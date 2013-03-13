Teststack README
===============

Teststack is a collection of bash scripts based on devstack and some OpenStack tutorials to deploy OpenStack in an automated and easy way.

Currently this script requires Ubuntu 12.04+

What is working(for the most part):
 * Keystone
 * Glance
 * Cinder
 * Swift

Currently working on:
 * Nova
 * Quantum
 * Horizon

Other services such as Heat and Ceilometer are not a high priority

How to use it
============

Before all the scripts were located in the main directory, but they are each located on a separate directory based on their fucntion. If you want to run a set of scripts you may want to move them or copy them to a given location(remember most scripts require the `functions.sh` script located in common/ directory).

Having all the files on separate directories and then having to move/copy them may seem like more work but at the end it will force the users(and me) to keep an organized workspace and to plan and organize their requierements before running any script.

Before running anything, make sure that the scripts you want and their requirements are in one place. You can also provide a `localrc` file with data that the script can use to automate the process.

To run the scripts just use `sudo <SCRIPT NAME>` or run the script as root. 

Also remember, some scripts require programs installed by other scripts, for exmaple, `install_keystone.sh` need MySQL access so you need to run `install_mysql.sh` before running `install_keystone.sh` 
