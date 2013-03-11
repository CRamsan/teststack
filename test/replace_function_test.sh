#!/bin/bash

source functions.sh

###################################################################################

func_replace "glance-api.conf" "admin_tenant_name = %SERVICE%" "admin_tenant_name = service"
