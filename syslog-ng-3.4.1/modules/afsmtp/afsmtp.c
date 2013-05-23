/*
 * Copyright (c) 2011-2012 BalaBit IT Ltd, Budapest, Hungary
 * Copyright (c) 2011-2012 Gergely Nagy <algernon@balabit.hu>
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 2 as published
 * by the Free Software Foundation, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *
 * As an additional exemption you are allowed to compile & link against the
 * OpenSSL libraries as published by the OpenSSL project. See the file
 * COPYING for details.
 *
 */

#include <signal.h>

#include "afsmtp.h"
#include "afsmtp-parser.h"
#include "plugin.h"
#include "messages.h"
#include "misc.h"
#include "stats.h"
#include "logqueue.h"

#include <libesmtp.h>

typedef struct
{
  gchar *name;
  gchar *template;
  LogTemplate *value;
} AFSMTPHeader;

typedef struct
{
  gchar *phrase;
  gchar *address;
  afsmtp_rcpt_type_t type;
} AFSMTPRecipient;

typedef struct
{
  LogDestDriver super;

  /* Shared between main/writer; only read by the writer, never
     written */
  gchar *host;
  gint port;

  gchar *subject;
  AFSMTPRecipient *mail_from;
  GList *rcpt_tos;
  GList *headers;
  gchar *body;

  time_t time_reopen;

  StatsCounterItem *dropped_messages;
  StatsCounterItem *stored_messages;

  LogTemplate *subject_tmpl;
  LogTemplate *body_tmpl;

  /* Thread related stuff; shared */
  GThread *writer_thread;
  GMutex *queue_mutex;
  GMutex *suspend_mutex;
  GCond *writer_thread_wakeup_cond;

  gboolean writer_thread_terminate;
  gboolean writer_thread_suspended;
  GTimeVal writer_thread_suspend_target;

  LogQueue *queue;

  /* Writer-only stuff */
  gint32 seq_num;
  GString *str;
} AFSMTPDriver;

static gchar *
afsmtp_wash_string (gchar *str)
{
  gint i;

  for (i = 0; i < strlen (str); i++)
    if (str[i] == '\n' ||
        str[i] == '\r')
      str[i] = ' ';

  return str;
}

/*
 * Configuration
 */

void
afsmtp_dd_set_host(LogDriver *d, const gchar *host)
{
  AFSMTPDriver *self = (AFSMTPDriver *)d;

  g_free(self->host);
  self->host = g_strdup (host);
}

void
afsmtp_dd_set_port(LogDriver *d, gint port)
{
  AFSMTPDriver *self = (AFSMTPDriver *)d;

  self->port = (int)port;
}

void
afsmtp_dd_set_subject(LogDriver *d, const gchar *subject)
{
  AFSMTPDriver *self = (AFSMTPDriver *)d;

  g_free(self->subject);
  self->subject = g_strdup(subject);
}

void
afsmtp_dd_set_from(LogDriver *d, const gchar *phrase, const gchar *mbox)
{
  AFSMTPDriver *self = (AFSMTPDriver *)d;

  g_free(self->mail_from->phrase);
  g_free(self->mail_from->address);
  self->mail_from->phrase = afsmtp_wash_string(g_strdup(phrase));
  self->mail_from->address = afsmtp_wash_string(g_strdup(mbox));
}

void
afsmtp_dd_add_rcpt(LogDriver *d, afsmtp_rcpt_type_t type, const gchar *phrase,
                   const gchar *mbox)
{
  AFSMTPDriver *self = (AFSMTPDriver *)d;
  AFSMTPRecipient *rcpt;

  rcpt = g_new0(AFSMTPRecipient, 1);
  rcpt->phrase = afsmtp_wash_string(g_strdup(phrase));
  rcpt->address = afsmtp_wash_string(g_strdup(mbox));
  rcpt->type = type;

  self->rcpt_tos = g_list_append(self->rcpt_tos, rcpt);
}

void
afsmtp_dd_set_body(LogDriver *d, const gchar *body)
{
  AFSMTPDriver *self = (AFSMTPDriver *)d;

  g_free(self->body);
  self->body = g_strdup(body);
}

gboolean
afsmtp_dd_add_header(LogDriver *d, const gchar *header, const gchar *value)
{
  AFSMTPDriver *self = (AFSMTPDriver *)d;
  AFSMTPHeader *h;

  if (!g_ascii_strcasecmp(header, "to") ||
      !g_ascii_strcasecmp(header, "cc") ||
      !g_ascii_strcasecmp(header, "bcc") ||
      !g_ascii_strcasecmp(header, "from") ||
      !g_ascii_strcasecmp(header, "sender") ||
      !g_ascii_strcasecmp(header, "reply-to") ||
      !g_ascii_strcasecmp(header, "date"))
    return FALSE;

  h = g_new0(AFSMTPHeader, 1);
  h->name = g_strdup(header);
  h->template = g_strdup(value);

  self->headers = g_list_append(self->headers, h);

  return TRUE;
}

/*
 * Utilities
 */
void
ignore_sigpipe (void)
{
  struct sigaction sa;

  sa.sa_handler = SIG_IGN;
  sigemptyset(&sa.sa_mask);
  sa.sa_flags = 0;
  sigaction(SIGPIPE, &sa, NULL);
}

static gchar *
afsmtp_dd_format_stats_instance(AFSMTPDriver *self)
{
  static gchar persist_name[1024];

  g_snprintf(persist_name, sizeof(persist_name),
             "smtp,%s,%u", self->host, self->port);
  return persist_name;
}

static void
afsmtp_dd_suspend(AFSMTPDriver *self)
{
  self->writer_thread_suspended = TRUE;
  g_get_current_time(&self->writer_thread_suspend_target);
  g_time_val_add(&self->writer_thread_suspend_target,
                 self->time_reopen * 1000000);
}

/*
 * Worker thread
 */
static void
afsmtp_dd_msg_add_recipient(AFSMTPRecipient *rcpt, smtp_message_t message)
{
  gchar *hdr;

  smtp_add_recipient(message, rcpt->address);

  switch (rcpt->type)
    {
    case AFSMTP_RCPT_TYPE_TO:
      hdr = "To";
      break;
    case AFSMTP_RCPT_TYPE_CC:
      hdr = "Cc";
      break;
    case AFSMTP_RCPT_TYPE_REPLY_TO:
      hdr = "Reply-To";
      break;
    default:
      return;
    }
  smtp_set_header(message, hdr, rcpt->phrase, rcpt->address);
  smtp_set_header_option(message, hdr, Hdr_OVERRIDE, 1);
}

static void
afsmtp_dd_msg_add_header(AFSMTPHeader *hdr, gpointer user_data)
{
  AFSMTPDriver *self = ((gpointer *)user_data)[0];
  LogMessage *msg = ((gpointer *)user_data)[1];
  smtp_message_t message = ((gpointer *)user_data)[2];

  log_template_format(hdr->value, msg, NULL, LTZ_SEND, self->seq_num, NULL, self->str);

  smtp_set_header(message, hdr->name, afsmtp_wash_string (self->str->str), NULL);
  smtp_set_header_option(message, hdr->name, Hdr_OVERRIDE, 1);
}

static void
afsmtp_dd_log_rcpt_status(smtp_recipient_t rcpt, const char *mailbox,
                          gpointer user_data)
{
  const smtp_status_t *status;

  status = smtp_recipient_status(rcpt);
  msg_debug("SMTP recipient result",
            evt_tag_str("recipient", mailbox),
            evt_tag_int("code", status->code),
            evt_tag_str("text", status->text),
            NULL);
}

static void
afsmtp_dd_cb_event(smtp_session_t session, int event, AFSMTPDriver *self)
{
  switch (event)
    {
    case SMTP_EV_CONNECT:
      msg_verbose("Connected to SMTP server",
                  evt_tag_str("host", self->host),
                  evt_tag_int("port", self->port),
                  NULL);
      break;
    case SMTP_EV_MAILSTATUS:
    case SMTP_EV_RCPTSTATUS:
    case SMTP_EV_MESSAGEDATA:
    case SMTP_EV_MESSAGESENT:
      /* Ignore */
      break;
    case SMTP_EV_DISCONNECT:
      msg_verbose("Disconnected from SMTP server",
                  evt_tag_str("host", self->host),
                  evt_tag_int("port", self->port),
                  NULL);
      break;
    default:
      msg_verbose("Unknown SMTP event",
                  evt_tag_int("event_id", event),
                  NULL);
      break;
    }
}

static void
afsmtp_dd_cb_monitor(const gchar *buf, gint buflen, gint writing,
                     AFSMTPDriver *self)
{
  gchar fmt[32];

  g_snprintf(fmt, sizeof(fmt), "%%.%us", buflen);

  switch (writing)
    {
    case SMTP_CB_READING:
      msg_debug ("SMTP Session: SERVER",
                 evt_tag_printf("message", fmt, buf),
                 NULL);
      break;
    case SMTP_CB_WRITING:
      msg_debug("SMTP Session: CLIENT",
                evt_tag_printf("message", fmt, buf),
                NULL);
      break;
    case SMTP_CB_HEADERS:
      msg_debug("SMTP Session: HEADERS",
                evt_tag_printf("data", fmt, buf),
                NULL);
      break;
    }
}

static gboolean
afsmtp_worker_insert(AFSMTPDriver *self)
{
  gboolean success;
  LogMessage *msg;
  LogPathOptions path_options = LOG_PATH_OPTIONS_INIT;
  smtp_session_t session;
  smtp_message_t message;
  gpointer args[] = { self, NULL, NULL };

  g_mutex_lock(self->queue_mutex);
  log_queue_reset_parallel_push(self->queue);
  success = log_queue_pop_head(self->queue, &msg, &path_options, FALSE, FALSE);
  g_mutex_unlock(self->queue_mutex);
  if (!success)
    return TRUE;

  msg_set_context(msg);

  session = smtp_create_session();
  message = smtp_add_message(session);

  g_string_printf(self->str, "%s:%d", self->host, self->port);
  smtp_set_server(session, self->str->str);

  smtp_set_eventcb(session, (smtp_eventcb_t)afsmtp_dd_cb_event, (void *)self);
  smtp_set_monitorcb(session, (smtp_monitorcb_t)afsmtp_dd_cb_monitor,
                     (void *)self, 1);

  smtp_set_reverse_path(message, self->mail_from->address);

  /* Defaults */
  smtp_set_header(message, "To", NULL, NULL);
  smtp_set_header(message, "From", NULL, NULL);

  log_template_format(self->subject_tmpl, msg, NULL, LTZ_SEND,
                      self->seq_num, NULL, self->str);
  smtp_set_header(message, "Subject", afsmtp_wash_string(self->str->str));
  smtp_set_header_option(message, "Subject", Hdr_OVERRIDE, 1);

  /* Add recipients */
  g_list_foreach(self->rcpt_tos, (GFunc)afsmtp_dd_msg_add_recipient, message);

  /* Add custom header (overrides anything set before, or in the
     body). */
  args[1] = msg;
  args[2] = message;
  g_list_foreach(self->headers, (GFunc)afsmtp_dd_msg_add_header, args);

  /* Set the body.
   *
   * We add a header to the body, otherwise libesmtp will not
   * recognise headers, and will append them to the end of the body.
   */
  g_string_assign(self->str, "X-Mailer: syslog-ng " VERSION "\r\n\r\n");
  log_template_append_format(self->body_tmpl, msg, NULL, LTZ_SEND,
                             self->seq_num, NULL, self->str);
  smtp_set_message_str(message, self->str->str);

  if (!smtp_start_session(session))
    {
      gchar error[1024];
      smtp_strerror(smtp_errno(), error, sizeof (error) - 1);

      msg_error("SMTP server error, suspending",
                evt_tag_str("error", error),
                evt_tag_int("time_reopen", self->time_reopen),
                NULL);
      success = FALSE;
    }
  else
    {
      const smtp_status_t *status = smtp_message_transfer_status(message);
      msg_debug("SMTP result",
                evt_tag_int("code", status->code),
                evt_tag_str("text", status->text),
                NULL);
      smtp_enumerate_recipients(message, afsmtp_dd_log_rcpt_status, NULL);
    }
  smtp_destroy_session(session);

  msg_set_context(NULL);

  if (success)
    {
      stats_counter_inc(self->stored_messages);
      step_sequence_number(&self->seq_num);
      log_msg_ack(msg, &path_options);
      log_msg_unref(msg);
    }
  else
    {
      g_mutex_lock(self->queue_mutex);
      log_queue_push_head(self->queue, msg, &path_options);
      g_mutex_unlock(self->queue_mutex);
    }

  return success;
}

static gpointer
afsmtp_worker_thread(gpointer arg)
{
  AFSMTPDriver *self = (AFSMTPDriver *)arg;

  msg_debug("Worker thread started",
            evt_tag_str("driver", self->super.super.id),
            NULL);

  self->str = g_string_sized_new(1024);

  ignore_sigpipe();

  while (!self->writer_thread_terminate)
    {
      g_mutex_lock(self->suspend_mutex);
      if (self->writer_thread_suspended)
        {
          g_cond_timed_wait(self->writer_thread_wakeup_cond,
                            self->suspend_mutex,
                            &self->writer_thread_suspend_target);
          self->writer_thread_suspended = FALSE;
          g_mutex_unlock(self->suspend_mutex);
        }
      else
        {
          g_mutex_unlock(self->suspend_mutex);

          g_mutex_lock(self->queue_mutex);
          if (log_queue_get_length(self->queue) == 0)
            {
              g_cond_wait(self->writer_thread_wakeup_cond, self->queue_mutex);
            }
          g_mutex_unlock(self->queue_mutex);
        }

      if (self->writer_thread_terminate)
        break;

      if (!afsmtp_worker_insert (self))
        {
          afsmtp_dd_suspend(self);
        }
    }

  g_string_free(self->str, TRUE);

  msg_debug("Worker thread finished",
            evt_tag_str("driver", self->super.super.id),
            NULL);

  return NULL;
}

/*
 * Main thread
 */

static void
afsmtp_dd_start_thread(AFSMTPDriver *self)
{
  self->writer_thread = create_worker_thread(afsmtp_worker_thread, self, TRUE, NULL);
}

static void
afsmtp_dd_stop_thread(AFSMTPDriver *self)
{
  self->writer_thread_terminate = TRUE;
  g_mutex_lock(self->queue_mutex);
  g_cond_signal(self->writer_thread_wakeup_cond);
  g_mutex_unlock(self->queue_mutex);
  g_thread_join(self->writer_thread);
}

static void
afsmtp_dd_init_header(AFSMTPHeader *hdr, GlobalConfig *cfg)
{
  if (!hdr->value)
    {
      hdr->value = log_template_new(cfg, hdr->name);
      log_template_compile(hdr->value, hdr->template, NULL);
    }
}

static gboolean
afsmtp_dd_init(LogPipe *s)
{
  AFSMTPDriver *self = (AFSMTPDriver *)s;
  GlobalConfig *cfg = log_pipe_get_config(s);

  if (cfg)
    self->time_reopen = cfg->time_reopen;

  msg_verbose("Initializing SMTP destination",
              evt_tag_str("host", self->host),
              evt_tag_int("port", self->port),
              NULL);

  self->queue = log_dest_driver_acquire_queue(&self->super, afsmtp_dd_format_stats_instance(self));

  g_list_foreach(self->headers, (GFunc)afsmtp_dd_init_header, cfg);
  if (!self->subject_tmpl)
    {
      self->subject_tmpl = log_template_new(cfg, "subject");
      log_template_compile(self->subject_tmpl, self->subject, NULL);
    }
  if (!self->body_tmpl)
    {
      self->body_tmpl = log_template_new(cfg, "body");
      log_template_compile(self->body_tmpl, self->body, NULL);
    }

  stats_lock();
  stats_register_counter(0, SCS_SMTP | SCS_DESTINATION, self->super.super.id,
                         afsmtp_dd_format_stats_instance(self),
                         SC_TYPE_STORED, &self->stored_messages);
  stats_register_counter(0, SCS_SMTP | SCS_DESTINATION, self->super.super.id,
                         afsmtp_dd_format_stats_instance(self),
                         SC_TYPE_DROPPED, &self->dropped_messages);
  stats_unlock();

  afsmtp_dd_start_thread(self);

  return TRUE;
}

static gboolean
afsmtp_dd_deinit(LogPipe *s)
{
  AFSMTPDriver *self = (AFSMTPDriver *)s;

  afsmtp_dd_stop_thread(self);

  stats_lock();
  stats_unregister_counter(SCS_SMTP | SCS_DESTINATION, self->super.super.id,
                           afsmtp_dd_format_stats_instance(self),
                           SC_TYPE_STORED, &self->stored_messages);
  stats_unregister_counter(SCS_SMTP | SCS_DESTINATION, self->super.super.id,
                           afsmtp_dd_format_stats_instance(self),
                           SC_TYPE_DROPPED, &self->dropped_messages);
  stats_unlock();

  return TRUE;
}

static void
afsmtp_dd_free(LogPipe *d)
{
  AFSMTPDriver *self = (AFSMTPDriver *)d;
  GList *l;

  g_mutex_free(self->suspend_mutex);
  g_mutex_free(self->queue_mutex);
  g_cond_free(self->writer_thread_wakeup_cond);

  if (self->queue)
    log_queue_unref(self->queue);

  g_free(self->host);
  g_free(self->mail_from->phrase);
  g_free(self->mail_from->address);
  g_free(self->mail_from);
  log_template_unref(self->subject_tmpl);
  log_template_unref(self->body_tmpl);
  g_free(self->body);
  g_free(self->subject);
  g_string_free(self->str, TRUE);

  l = self->rcpt_tos;
  while (l)
    {
      AFSMTPRecipient *rcpt = (AFSMTPRecipient *)l->data;
      g_free(rcpt->address);
      g_free(rcpt->phrase);
      g_free(rcpt);
      l = g_list_delete_link(l, l);
    }

  l = self->headers;
  while (l)
    {
      AFSMTPHeader *hdr = (AFSMTPHeader *)l->data;
      g_free(hdr->name);
      g_free(hdr->template);
      log_template_unref(hdr->value);
      g_free(hdr);
      l = g_list_delete_link(l, l);
    }

  log_dest_driver_free(d);
}

static void
afsmtp_dd_queue_notify(gpointer s)
{
  AFSMTPDriver *self = (AFSMTPDriver *)s;

  g_mutex_lock(self->queue_mutex);
  g_cond_signal(self->writer_thread_wakeup_cond);
  log_queue_reset_parallel_push(self->queue);
  g_mutex_unlock(self->queue_mutex);
}

static void
afsmtp_dd_queue(LogPipe *s, LogMessage *msg,
                const LogPathOptions *path_options, gpointer user_data)
{
  AFSMTPDriver *self = (AFSMTPDriver *)s;
  gboolean queue_was_empty;
  LogPathOptions local_options;

  if (!path_options->flow_control_requested)
    path_options = log_msg_break_ack(msg, path_options, &local_options);

  g_mutex_lock(self->queue_mutex);
  queue_was_empty = log_queue_get_length(self->queue) == 0;
  g_mutex_unlock(self->queue_mutex);

  log_msg_add_ack(msg, path_options);
  log_queue_push_tail(self->queue, log_msg_ref(msg), path_options);

  g_mutex_lock(self->suspend_mutex);
  if (queue_was_empty && !self->writer_thread_suspended)
    {
      g_mutex_lock(self->queue_mutex);
      log_queue_set_parallel_push(self->queue, 1, afsmtp_dd_queue_notify, self, NULL);
      g_mutex_unlock(self->queue_mutex);
    }
  g_mutex_unlock(self->suspend_mutex);
  log_dest_driver_queue_method(s, msg, path_options, user_data);
}

/*
 * Plugin glue.
 */

LogDriver *
afsmtp_dd_new(void)
{
  AFSMTPDriver *self = g_new0(AFSMTPDriver, 1);

  log_dest_driver_init_instance(&self->super);
  self->super.super.super.init = afsmtp_dd_init;
  self->super.super.super.deinit = afsmtp_dd_deinit;
  self->super.super.super.queue = afsmtp_dd_queue;
  self->super.super.super.free_fn = afsmtp_dd_free;

  afsmtp_dd_set_host((LogDriver *)self, "127.0.0.1");
  afsmtp_dd_set_port((LogDriver *)self, 25);

  self->mail_from = g_new0(AFSMTPRecipient, 1);

  init_sequence_number(&self->seq_num);

  self->writer_thread_wakeup_cond = g_cond_new();
  self->suspend_mutex = g_mutex_new();
  self->queue_mutex = g_mutex_new();

  return (LogDriver *)self;
}

extern CfgParser afsmtp_dd_parser;

static Plugin afsmtp_plugin =
{
  .type = LL_CONTEXT_DESTINATION,
  .name = "smtp",
  .parser = &afsmtp_parser,
};

gboolean
afsmtp_module_init(GlobalConfig *cfg, CfgArgs *args)
{
  plugin_register(cfg, &afsmtp_plugin, 1);
  return TRUE;
}

const ModuleInfo module_info =
{
  .canonical_name = "afsmtp",
  .version = VERSION,
  .description = "The afsmtp module provides SMTP destination support for syslog-ng.",
  .core_revision = SOURCE_REVISION,
  .plugins = &afsmtp_plugin,
  .plugins_len = 1,
};
