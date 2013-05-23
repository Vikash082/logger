# Creating softlink for ES to run as daemon
#echo "Creating softlink for ES to run as daemon"
#sudo ln -s elasticsearch-0.90.0/ elasticsearch
#echo "Changing the permission of ES"
#sudo chown -R root:root elasticsearch
#cd elasticsearch-0.90.0/
#echo "Starting elastic search"
#bin/service/elasticsearch start
#echo "Elastic search started, PID: " $(pgrep elasticsearch)

#Install Redis
#echo "Installing Redis"
#cd redis-2.6.13
#make clean && make distclean
#make install
# Daemonize Redis
#echo "Daemonizing Redis"
#sed -i -e 's/daemonize no/daemonize yes/g' redis.conf
#echo "daemonize yes" >> redis.conf
#echo "Starting redis-server"
#src/redis-server
#echo "Redis Server started, PID: " $(pgrep redis-server)
