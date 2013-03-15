#!/bin/bash
./install_base.sh
./install_mysql.sh
./install_cinder.sh
echo "Prepare the partiton you want to use"
exit
./populate_cinder.sh
