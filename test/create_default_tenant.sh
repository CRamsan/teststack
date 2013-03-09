
#!/bin/bash

source functions.sh
source localrc

###################################################################################

##Check for the existance of a default tenant's name and their ID.
if [ ! -n "$DEFTENANTNAME" ] || [ ! -n "$DEFTENANTID" ]
then
        echo "What is going to be the name for the default tenant?:"
        DEFTENANTNAME=$(func_ask_user)
        func_set_value "DEFTENANTNAME" $DEFTENANTNAME

        #func_echo "func_create_tenant \"$ADMINTOKEN\" \"$KEYSTONEIP\" \"$DEFTENANTNAME\""

        DEFTENANTID=$(func_create_tenant "$ADMINTOKEN" "$KEYSTONEIP" "$DEFTENANTNAME" )
        func_set_value "DEFTENANTID" $DEFTENANTID
fi


