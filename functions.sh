function func_install {
	COMMAND_INSTALL="apt-get install -y"
	if [ ! -n "$1" ]
	then
		func_echo "No parameter for install function"
		exit 1
	else
		for package in "$@"
		do
			args="$args $package"
		done
		COMMAND_INSTALL="$COMMAND_INSTALL $args"
		func_echo "$COMMAND_INSTALL"
		$COMMAND_INSTALL
		if [ $? -eq 0 ]
		then
			func_echo "Install process of packages $1 run correctly "
		else
			func_echo "Install process of packages $1 failed"
			exit 1
		fi
	fi
}

function func_pre {
	func_install debconf
}

function func_install_my-sql {
	if [ ! -n "$1" ]
	then
        	func_echo "No password provided"
		func_echo "Exiting now"
           	exit 1
       	else
		PASSWORD=$1
		echo mysql-server mysql-server/root_password select $PASSWORD | debconf-set-selections
		echo mysql-server mysql-server/root_password_again select $PASSWORD | debconf-set-selections
	fi
	func_install mysql-server
	func_install python-mysqldb
}

function funct_add_cloud_archive {
	apt-get update
	apt-get upgrade -y
	apt-get install ubuntu-cloud-keyring
	echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu precise-updates/grizzly main" > /etc/apt/sources.list.d/grizzly.list	
	apt-get update
}

function func_ask_user {
	read -e val
	echo $val
}

function func_set_value {
	key=$1
	val=$2
	eval "$key=$val"
        echo "export $key=$val" >> $localrc
}

function func_set_password {
	var=$1
	mesg=$2
	pw=" "
	while true; do
		func_echo "Enter a password used for: $mesg."
		func_echo "If no password is provided, a random password will be generated:"
	        read -e $var
	        pw=${!var}
	        [[ "$pw" = "`echo $pw | tr -cd [:alnum:]`" ]] && break
	        func_echo "Invalid chars in password.  Try again:"
	done
	if [ ! $pw ]; then
		pw=`openssl rand -hex 10`
		func_echo "Password: $pw"
	fi
	func_set_value "$var" "$pw"
}

function func_retrieve_value {
	key=$1
	grep "$key" "$localrc" | cut -d'=' -f2 | sed 's/export //g'
}

function func_clear_values {
	rm "$localrc"
}

function func_replace_param {
	file=$1
	parameter=$2
	newvalue=$3
	func_echo "In file $file - Parameter \"$parameter\" is been set to \"$newvalue\""
	func_echo "Press ENTER to open a text editor"
	read
	while [ $answer != "yes" & $answer != "YES" ]
	do
		nano $file
		func_echo "Are you done doing changes? [yes/NO]"
		read -e answer
		func_echo "In file $file - Parameter \"$parameter\" is been set to \"$newvalue\""
	done
}

function func_create_tenant {
	ADMINTOKEN=$1
	KEYSTONEIP=$2
	TENANTNAME=$3
	DESCRIPTION="No description"
       	TENANTID=$(keystone --token "$ADMINTOKEN" --endpoint http://"$KEYSTONEIP":35357/v2.0 tenant-create \
		--name "$TENANTNAME" \
		--description "$DESCRIPTION \
		| 's/ //g' | grep "|id|" |cut -d'|' -f3)
	echo $TENANTID
}

function func_create_user {
	ADMINTOKEN=$1
	KEYSTONEIP=$2
	TENANTID=$3
	USERNAME=$4
	PASSWORD=$5
	USERID=$(keystone --token "$ADMINTOKEN" --endpoint http://"$KEYSTONEIP":35357/v2.0 user-create \
		--tenant_id "$TENANTID" \
		--name "$USERNAME" \
		--pass "$PASSWORD \
		| 's/ //g'  | grep "|id|" | cut -d'|' -f3)
	echo $USERID
}

function func_create_role {
	ADMINTOKEN=$1
	KEYSTONEIP=$2
	ROLENAME=$3
	ROLEID=$(keystone --token "$ADMINTOKEN" --endpoint http://"$KEYSTONEIP":35357/v2.0 role-create \
		--name "$ROLENAME \
		| 's/ //g'  | grep "|id|" |cut -d'|' -f3)
	echo $ROLEID
}

function func_user_role_add {
	ADMINTOKEN=$1
	KEYSTONEIP=$2
	USERID=$3
	TENANTID=$4
	ROLEID=$5
	keystone --token "$ADMINTOKEN" --endpoint http://"$KEYSTONEIP":35357/v2.0 user-role-add \
		--user "$USERID" \
		--tenant_id "$TENANTID" \
		--role "$ROLEID"
}

function func_create_service {
        ADMINTOKEN=$1
        KEYSTONEIP=$2
        SERVNAME=$3
        SERVTYPE=$4
        SERVDESC=$5
	SERVIP=$6
	SERVID=$(keystone --token "$ADMINTOKEN" --endpoint http://"$KEYSTONEIP":35357/v2.0 service-create \
		--name="$SERVNAME" \
		--type="$SERVTYPE"  \
		--description="$SERVDESC \
		| 's/ //g'  | grep "|id|" | cut -d'|' -f3)

	if [ "$SERVTYPE" eq "compute" ]
	then
		ENDPOINTID=$(keystone --token "$ADMINTOKEN" --endpoint http://"$KEYSTONEIP":35357/v2.0 endpoint-create \
		--region "RegionOne" \
		--service_id "$SERVID" \
		--publicurl "http://$SERVIP:8774/v2/%(tenant_id)s" \
		--adminurl "http://$SERVIP:8774/v2/%(tenant_id)s" \
		--internalurl "http://$SERVIP:8774/v2/%(tenant_id)s" \
		| 's/ //g'  | grep "|id|" | cut -d'|' -f3)
	elif [ "$SERVTYPE" eq "volume" ]
	then
                ENDPOINTID=$(keystone --token "$ADMINTOKEN" --endpoint http://"$KEYSTONEIP":35357/v2.0 endpoint-create \
                --region "RegionOne" \
                --service_id "$SERVID" \
		--publicurl "http://$SERVIP:8776/v1/%(tenant_id)s" \
		--adminurl "http://$SERVIP:8776/v1/%(tenant_id)s" \
		--internalurl "http://$SERVIP:8776/v1/%(tenant_id)s" \
		| 's/ //g'  | grep "|id|" | cut -d'|' -f3)
        elif [ "$SERVTYPE" eq "image" ]
	then
                ENDPOINTID=$(keystone --token "$ADMINTOKEN" --endpoint http://"$KEYSTONEIP":35357/v2.0 endpoint-create \
                --region "RegionOne" \
                --service_id "$SERVID" \
		--publicurl "http://$SERVIP:9292" \
		--adminurl "http://$SERVIP:9292" \
		--internalurl "http://$SERVIP:9292" \
		| 's/ //g'  | grep "|id|" | cut -d'|' -f3)
        elif [ "$SERVTYPE" eq "object-store" ]
	then
                ENDPOINTID=$(keystone --token "$ADMINTOKEN" --endpoint http://"$KEYSTONEIP":35357/v2.0 endpoint-create \
                --region "RegionOne" \
                --service_id "$SERVID" \
		--publicurl "http://$SERVIP:8080/v1/AUTH_%(tenant_id)s" \
		--adminurl "http://$SERVIP:8080/v1" \
		--internalurl "http://$SERVIP:8080/v1/AUTH_%(tenant_id)s" \
		| 's/ //g'  | grep "|id|" | cut -d'|' -f3)
        elif [ "$SERVTYPE" eq "identity" ]
	then
                ENDPOINTID=$(keystone --token "$ADMINTOKEN" --endpoint http://"$KEYSTONEIP":35357/v2.0 endpoint-create \
                --region "RegionOne" \
                --service_id "$SERVID" \
		--publicurl "http://$SERVIP0:5000/v2.0" \
		--adminurl "http://$SERVIP:35357/v2.0" \
		--internalurl "http://$SERVIP:5000/v2.0" \
		| 's/ //g'  | grep "|id|" | cut -d'|' -f3)
        elif [ "$SERVTYPE" eq "ec2" ]
	then
                ENDPOINTID=$(keystone --token "$ADMINTOKEN" --endpoint http://"$KEYSTONEIP":35357/v2.0 endpoint-create \
                --region "RegionOne" \
                --service_id "$SERVID" \
		--publicurl "http://$SERVIP:8773/services/Cloud" \
		--adminurl "http://$SERVIP:8773/services/Admin" \
		--internalurl "http://$SERVIP:8773/services/Cloud" \
		| 's/ //g'  | grep "|id|" | cut -d'|' -f3)
        elif [ "$SERVTYPE" eq "network" ]
	then
                ENDPOINTID=$(keystone --token "$ADMINTOKEN" --endpoint http://"$KEYSTONEIP":35357/v2.0 endpoint-create \
                --region "RegionOne" \
                --service_id "$SERVID" \
		--publicurl "http://$SERVIP:9696/v2" \
		--adminurl "http://$SERVIP:9696/v2" \
		--internalurl "http://$SERVIP:9696/v2" \
		| 's/ //g'  | grep "|id|" | cut -d'|' -f3)
	fi
	echo $ENDPOINTID
}



function func_echo {
	MSG=$1
	echo -e "\E[32m$MSG"
	tput sgr0
}
