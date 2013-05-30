# This file should be in monitor directory
echo "Starting Elastic search"
cd monitor/elasticsearch-0.90.0
bin/service/elasticsearch start
cd ../
##java -jar logstash-1.1.10-flatjar.jar agent -f syslog.conf 2>shipper_log &
##java -jar logstash-1.1.10-flatjar.jar agent -f indexer_syslog.conf 2>indexer_log &

echo "Checking status of logstash_shipper"
service logstash_shipper_syslog status
echo "Starting logstash_shipper"
service logstash_shipper_syslog start
echo "Checking status of logstash_indexer"
service logstash_indexer_syslog status
echo "Starting logstash_indexer"
service logstash_indexer_syslog start
echo "Staring kibana service"
service kibana.init.sh start
##cd Kibana-0.2.0
##ruby kibana.rb 2>/var/log/Kibana/kibana_log&
cd redis-2.6.13/
src/redis-server
