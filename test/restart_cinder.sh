source functions.sh
source localrc

sudo service cinder-volume restart
sudo service cinder-api restart
sudo service cinder-scheduler restart
