cd elasticsearch-0.90.0/
echo "Stopping Elasticsearch services"
bin/service/elasticsearch stop
echo "Stopping logstash services"
service logstash_shipper_syslog stop
service logstash_indexer_syslog stop
echo "Stopping Kibana"
pkill $pgrep ruby
echo "Stopping Redis-server"
pkill $pgrep redis
echo "Checking Elasticsearch services"
bin/service/elasticsearch status
echo "Checking logstash services"
service logstash_shipper_syslog status
service logstash_indexer_syslog status
echo "Checking Kibana status"
ps -elf| grep kibana
echo "Checking redis status"
ps -elf| grep redis
echo "All the logging services are stopped"
