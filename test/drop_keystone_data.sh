source functions.sh
source localrc

set -x

keystone --token "$ADMINTOKEN"  --endpoint http://"$KEYSTONEIP":35357/v2.0 user-delete $USERID
keystone --token "$ADMINTOKEN"  --endpoint http://"$KEYSTONEIP":35357/v2.0 user-delete $ADMINUSERID
keystone --token "$ADMINTOKEN"  --endpoint http://"$KEYSTONEIP":35357/v2.0 role-delete $ROLEID
keystone --token "$ADMINTOKEN"  --endpoint http://"$KEYSTONEIP":35357/v2.0 role-delete $ADMINROLEID
keystone --token "$ADMINTOKEN"  --endpoint http://"$KEYSTONEIP":35357/v2.0 tenant-delete $SERVTENANTID
keystone --token "$ADMINTOKEN"  --endpoint http://"$KEYSTONEIP":35357/v2.0 tenant-delete $DEFTENANTID
keystone --token "$ADMINTOKEN"  --endpoint http://"$KEYSTONEIP":35357/v2.0 tenant-delete $TENANTID
keystone --token "$ADMINTOKEN"  --endpoint http://"$KEYSTONEIP":35357/v2.0 user-delete $USERNOVAID
keystone --token "$ADMINTOKEN"  --endpoint http://"$KEYSTONEIP":35357/v2.0 user-delete $USERGLANCEID
keystone --token "$ADMINTOKEN"  --endpoint http://"$KEYSTONEIP":35357/v2.0 user-delete $USERCINDERID
keystone --token "$ADMINTOKEN"  --endpoint http://"$KEYSTONEIP":35357/v2.0 user-delete $USERQUANTUMID
keystone --token "$ADMINTOKEN"  --endpoint http://"$KEYSTONEIP":35357/v2.0 user-delete $USEREC2ID
keystone --token "$ADMINTOKEN"  --endpoint http://"$KEYSTONEIP":35357/v2.0 user-delete $USERSWIFTID
keystone --token "$ADMINTOKEN"  --endpoint http://"$KEYSTONEIP":35357/v2.0 endpoint-delete $novaENDID
keystone --token "$ADMINTOKEN"  --endpoint http://"$KEYSTONEIP":35357/v2.0 endpoint-delete $cinderENDID
keystone --token "$ADMINTOKEN"  --endpoint http://"$KEYSTONEIP":35357/v2.0 endpoint-delete $glanceENDID
keystone --token "$ADMINTOKEN"  --endpoint http://"$KEYSTONEIP":35357/v2.0 endpoint-delete $swiftENDID
keystone --token "$ADMINTOKEN"  --endpoint http://"$KEYSTONEIP":35357/v2.0 endpoint-delete $keystoneENDID
keystone --token "$ADMINTOKEN"  --endpoint http://"$KEYSTONEIP":35357/v2.0 endpoint-delete $ec2ENDID
keystone --token "$ADMINTOKEN"  --endpoint http://"$KEYSTONEIP":35357/v2.0 endpoint-delete $quantumENDID
keystone --token "$ADMINTOKEN"  --endpoint http://"$KEYSTONEIP":35357/v2.0 service-delete $novaSERVID
keystone --token "$ADMINTOKEN"  --endpoint http://"$KEYSTONEIP":35357/v2.0 service-delete $cinderSERVID
keystone --token "$ADMINTOKEN"  --endpoint http://"$KEYSTONEIP":35357/v2.0 service-delete $glanceSERVID
keystone --token "$ADMINTOKEN"  --endpoint http://"$KEYSTONEIP":35357/v2.0 service-delete $swiftSERVID
keystone --token "$ADMINTOKEN"  --endpoint http://"$KEYSTONEIP":35357/v2.0 service-delete $keystoneSERVID
keystone --token "$ADMINTOKEN"  --endpoint http://"$KEYSTONEIP":35357/v2.0 service-delete $ec2SERVID
keystone --token "$ADMINTOKEN"  --endpoint http://"$KEYSTONEIP":35357/v2.0 service-delete $quantumSERVID
