[DEFAULT]
#bind_host=0.0.0.0
public_port=5000
admin_port=35357
admin_token=93a4a7f50df80b58b4af
compute_port=8774
verbose=True
debug=True
log_config=/etc/keystone/logging.conf

#=================SyslogOptions============================
#Sendlogstosyslog(/dev/log)insteadoftofilespecified
#by`log-file`
use_syslog=False

#Facilitytouse.IfunsetdefaultstoLOG_USER.
#syslog_log_facility=LOG_LOCAL0

[sql]
connection=mysql://keystone:4e7e9ded979c30cb2b9d@192.168.0.150/keystone
idle_timeout=200

[ldap]
#url=ldap://localhost
#tree_dn=dc=example,dc=com
#user_tree_dn=ou=Users,dc=example,dc=com
#role_tree_dn=ou=Roles,dc=example,dc=com
#tenant_tree_dn=ou=Groups,dc=example,dc=com
#user=dc=Manager,dc=example,dc=com
#password=freeipa4all
#suffix=cn=example,cn=com

[identity]
driver=keystone.identity.backends.sql.Identity

[catalog]
driver=keystone.catalog.backends.sql.Catalog

[token]
driver=keystone.token.backends.sql.Token

#Amountoftimeatokenshouldremainvalid(inseconds)
expiration=86400

[policy]
driver=keystone.policy.backends.rules.Policy

[ec2]
driver=keystone.contrib.ec2.backends.sql.Ec2

[filter:debug]
paste.filter_factory=keystone.common.wsgi:Debug.factory

[filter:token_auth]
paste.filter_factory=keystone.middleware:TokenAuthMiddleware.factory

[filter:admin_token_auth]
paste.filter_factory=keystone.middleware:AdminTokenAuthMiddleware.factory

[filter:xml_body]
paste.filter_factory=keystone.middleware:XmlBodyMiddleware.factory

[filter:json_body]
paste.filter_factory=keystone.middleware:JsonBodyMiddleware.factory

[filter:crud_extension]
paste.filter_factory=keystone.contrib.admin_crud:CrudExtension.factory

[filter:ec2_extension]
paste.filter_factory=keystone.contrib.ec2:Ec2Extension.factory

[app:public_service]
paste.app_factory=keystone.service:public_app_factory

[app:admin_service]
paste.app_factory=keystone.service:admin_app_factory

[pipeline:public_api]
pipeline=token_authadmin_token_authxml_bodyjson_bodydebugec2_extensionpublic_service

[pipeline:admin_api]
pipeline=token_authadmin_token_authxml_bodyjson_bodydebugec2_extensioncrud_extensionadmin_service

[app:public_version_service]
paste.app_factory=keystone.service:public_version_app_factory

[app:admin_version_service]
paste.app_factory=keystone.service:admin_version_app_factory

[pipeline:public_version_api]
pipeline=xml_bodypublic_version_service

[pipeline:admin_version_api]
pipeline=xml_bodyadmin_version_service

[composite:main]
use=egg:Paste#urlmap
/v2.0=public_api
/=public_version_api

[composite:admin]
use=egg:Paste#urlmap
/v2.0=admin_api
/=admin_version_api