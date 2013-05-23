/* config.h.  Generated from config.h.in by configure.  */
/* config.h.in.  Generated from configure.in by autoheader.  */

/* Enable debugging */
#define ENABLE_DEBUG 0

/* Enable environment wrapper support */
#define ENABLE_ENV_WRAPPER 0

/* Enable gcc profiling */
#define ENABLE_GPROF 0

/* Enable IPv6 support */
#define ENABLE_IPV6 1

/* Enable libuuid support */
#define ENABLE_LIBUUID 0

/* Enable Linux capability management support */
#define ENABLE_LINUX_CAPS 0

/* Enable memtrace */
#define ENABLE_MEMTRACE 0

/* Enable PCRE support */
#define ENABLE_PCRE 1

/* Enable spoof source support */
#define ENABLE_SPOOF_SOURCE 0

/* Enable SSL support */
#define ENABLE_SSL 1

/* Enable systemd support */
#define ENABLE_SYSTEMD 1

/* Enable TCP wrapper support */
#define ENABLE_TCP_WRAPPER 0

/* set LD_LIBRARY_PATH to this value */
/* #undef ENV_LD_LIBRARY_PATH */

/* define if your platform has a broken pread/pwrite (e.g. HP-UX) */
/* #undef HAVE_BROKEN_PREAD */

/* Define to 1 if you have the `clock_gettime' function. */
#define HAVE_CLOCK_GETTIME 1

/* Define to 1 if you have the <dlfcn.h> header file. */
#define HAVE_DLFCN_H 1

/* Define to 1 if you have the <door.h> header file. */
/* #undef HAVE_DOOR_H */

/* Specifies whether the environ global variable exists */
#define HAVE_ENVIRON 1

/* Define to 1 if you have the `getaddrinfo' function. */
#define HAVE_GETADDRINFO 1

/* Define to 1 if you have the `getnameinfo' function. */
#define HAVE_GETNAMEINFO 1

/* Define to 1 if you have the <getopt.h> header file. */
#define HAVE_GETOPT_H 1

/* Define to 1 if you have the `getopt_long' function. */
#define HAVE_GETOPT_LONG 1

/* Define to 1 if you have the `getutent' function. */
#define HAVE_GETUTENT 1

/* Define to 1 if you have the `getutxent' function. */
#define HAVE_GETUTXENT 1

/* Define to 1 if you have the `gmtime_r' function. */
#define HAVE_GMTIME_R 1

/* Define to 1 if you have the `g_mapped_file_unref' function. */
/* #undef HAVE_G_MAPPED_FILE_UNREF */

/* Define to 1 if you have the `inet_aton' function. */
#define HAVE_INET_ATON 1

/* Define to 1 if you have the `inet_ntoa' function. */
#define HAVE_INET_NTOA 1

/* Define to 1 if you have the <inttypes.h> header file. */
#define HAVE_INTTYPES_H 1

/* Define to 1 if you have the `pthread' library (-lpthread). */
/* #undef HAVE_LIBPTHREAD */

/* Define to 1 if you have the `localtime_r' function. */
#define HAVE_LOCALTIME_R 1

/* Define to 1 if you have the <memory.h> header file. */
#define HAVE_MEMORY_H 1

/* Define to 1 if you have the `memrchr' function. */
#define HAVE_MEMRCHR 1

/* O_LARGEFILE is present */
#define HAVE_O_LARGEFILE 1

/* Define to 1 if you have the `pread' function. */
#define HAVE_PREAD 1

/* have PR_SET_KEEPCAPS */
#define HAVE_PR_SET_KEEPCAPS 1

/* Define to 1 if you have the <pthread.h> header file. */
/* #undef HAVE_PTHREAD_H */

/* Define to 1 if you have the `pwrite' function. */
#define HAVE_PWRITE 1

/* SO_ACCEPTCONN is present */
#define HAVE_SO_ACCEPTCONN 1

/* Define to 1 if you have the <stdint.h> header file. */
#define HAVE_STDINT_H 1

/* Define to 1 if you have the <stdlib.h> header file. */
#define HAVE_STDLIB_H 1

/* Define to 1 if you have the `strcasestr' function. */
#define HAVE_STRCASESTR 1

/* Define to 1 if you have the `strdup' function. */
#define HAVE_STRDUP 1

/* Define to 1 if you have the <strings.h> header file. */
#define HAVE_STRINGS_H 1

/* Define to 1 if you have the <string.h> header file. */
#define HAVE_STRING_H 1

/* Define to 1 if you have the <stropts.h> header file. */
#define HAVE_STROPTS_H 1

/* Define to 1 if you have the `strtoimax' function. */
#define HAVE_STRTOIMAX 1

/* Define to 1 if you have the `strtol' function. */
#define HAVE_STRTOL 1

/* Define to 1 if you have the `strtoll' function. */
#define HAVE_STRTOLL 1

/* struct sockaddr_storage is present on your system */
#define HAVE_STRUCT_SOCKADDR_STORAGE 1

/* Whether you have tm_gmtoff field in struct tm */
#define HAVE_STRUCT_TM_TM_GMTOFF 1

/* Define to 1 if you have the <sys/capability.h> header file. */
/* #undef HAVE_SYS_CAPABILITY_H */

/* Define to 1 if you have the <sys/prctl.h> header file. */
#define HAVE_SYS_PRCTL_H 1

/* Define to 1 if you have the <sys/stat.h> header file. */
#define HAVE_SYS_STAT_H 1

/* Define to 1 if you have the <sys/strlog.h> header file. */
/* #undef HAVE_SYS_STRLOG_H */

/* Define to 1 if you have the <sys/types.h> header file. */
#define HAVE_SYS_TYPES_H 1

/* Define to 1 if you have the <tcpd.h> header file. */
/* #undef HAVE_TCPD_H */

/* "Whether Transport Layer Security is supported by the system" */
#define HAVE_THREAD_KEYWORD 1

/* Define to 1 if you have the <unistd.h> header file. */
#define HAVE_UNISTD_H 1

/* Define to 1 if you have the <utmpx.h> header file. */
#define HAVE_UTMPX_H 1

/* Define to 1 if you have the <utmp.h> header file. */
#define HAVE_UTMP_H 1

/* Required license version */
#define LICENSE_VERSION ""

/* Define to the sub-directory in which libtool stores uninstalled libraries.
   */
#define LT_OBJDIR ".libs/"

/* module search path */
#define MODULE_PATH "/usr/local/lib/syslog-ng"

/* package name */
#define PACKAGE "syslog-ng"

/* Define to the address where bug reports for this package should be sent. */
#define PACKAGE_BUGREPORT ""

/* Define to the full name of this package. */
#define PACKAGE_NAME ""

/* Define to the full name and version of this package. */
#define PACKAGE_STRING ""

/* Define to the one symbol short name of this package. */
#define PACKAGE_TARNAME ""

/* Define to the home page for this package. */
#define PACKAGE_URL ""

/* Define to the version of this package. */
#define PACKAGE_VERSION ""

/* data directory */
#define PATH_DATADIR "/usr/local/share"

/* data root directory */
#define PATH_DATAROOTDIR "/usr/local/share"

/* libexec directory */
#define PATH_LIBEXECDIR "/usr/local/libexec"

/* local state directory */
#define PATH_LOCALSTATEDIR "/usr/local/var"

/* local state directory */
#define PATH_PIDFILEDIR "/usr/local/var"

/* prefix directory */
#define PATH_PREFIX "/usr/local"

/* sysconfdir */
#define PATH_SYSCONFDIR "/usr/local/etc"

/* timezone base directory */
/* #undef PATH_TIMEZONEDIR */

/* source revision */
#define SOURCE_REVISION ""

/* Define to 1 if you have the ANSI C header files. */
#define STDC_HEADERS 1

/* Define to 1 if your <sys/time.h> declares `struct tm'. */
/* #undef TM_IN_SYS_TIME */

/* version number */
#define VERSION "3.4.1"

/* Include the compile date in the binary */
#define WITH_COMPILE_DATE 1

/* Compile with libsystemd-daemon */
#define WITH_LIBSYSTEMD 0

/* Define to 1 if `lex' declares `yytext' as a `char *' by default, not a
   `char[]'. */
#define YYTEXT_POINTER 1

/* Enable large inode numbers on Mac OS X 10.5.  */
#ifndef _DARWIN_USE_64_BIT_INODE
# define _DARWIN_USE_64_BIT_INODE 1
#endif

/* Number of bits in a file offset, on hosts where this is settable. */
#define _FILE_OFFSET_BITS 64

/* Define for large files, on AIX-style hosts. */
/* #undef _LARGE_FILES */
