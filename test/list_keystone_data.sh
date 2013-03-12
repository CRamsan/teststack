source functions.sh
source keystonerc

set -x

keystone tenant-list
keystone role-list
keystone user-list
keystone service-list
keystone endpoint-list
