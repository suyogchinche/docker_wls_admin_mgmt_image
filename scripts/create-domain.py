# Config domain
# ==============================================
domain_name  = os.environ.get("DOMAIN_NAME", "base_domain")
admin_port   = int(os.environ.get("ADMIN_PORT", "8001"))
admin_pass   = os.environ.get("ADMIN_PASSWORD", "welcome1")
cluster_name = os.environ.get("CLUSTER_NAME", "DockerCluster")
domain_path  = '/home/oracle/domains/%s' % domain_name
production_mode = os.environ.get("PRODUCTION_MODE", "prod")

print('domain_name : [%s]' % domain_name);
print('admin_port  : [%s]' % admin_port);
print('cluster_name: [%s]' % cluster_name);
print('domain_path : [%s]' % domain_path);
print('production_mode : [%s]' % production_mode);

# Open default domain template
# ======================
readTemplate("/home/oracle/weblogic/wlserver/common/templates/wls/wls.jar")

set('Name', domain_name)
setOption('DomainName', domain_name)

# Disable Admin Console
# --------------------
# cmo.setConsoleEnabled(false)

# Configure the Administration Server and SSL port.
# =========================================================
cd('/Servers/AdminServer')
set('ListenAddress', '')
set('ListenPort', admin_port)

# Define the user password for weblogic
# =====================================
cd('/Security/%s/User/weblogic' % domain_name)
cmo.setPassword(admin_pass)

# Write the domain and close the domain template
# ==============================================
setOption('OverwriteDomain', 'true')
setOption('ServerStartMode',production_mode)

# Define a WebLogic Cluster
# =========================
cd('/')
create(cluster_name, 'Cluster')

cd('/Clusters/%s' % cluster_name)
cmo.setClusterMessagingMode('unicast')

# Write Domain
# ============
writeDomain(domain_path)
closeTemplate()

# Exit WLST
# =========
exit()
