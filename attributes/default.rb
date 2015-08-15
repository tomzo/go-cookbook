default['go']['backup_path'] = ''
default['go']['backup_retrieval_type'] = 'subversion'

default['go']['agent']['auto_register']         = false
default['go']['agent']['auto_register_key']     = 'default_auto_registration_key'
default['go']['agent']['auto_register_resources'] = []
default['go']['agent']['auto_register_environments'] = []

# Install this many agent instances on a box - default is one per CPU

default['go']['agent']['instance_count'] = node['cpu']['total']
default['go']['agent']['server_search_query'] =
  "chef_environment:#{node.chef_environment} AND recipes:go\\:\\:server"


default['go']['version']                       = '14.3.0-1186'

unless platform?('windows')
  default['go']['agent']['java_home']             = '/usr/bin/java'
  default['go']['agent']['work_dir_path']         = '/var/lib'
end

default['go']['server']['install_path'] = 'C:\Program Files (x86)\Go Server'

default['go']['install_method'] = 'repository'

default['go']['repository']['apt']['uri'] = 'http://download.go.cd/gocd-deb/'
default['go']['repository']['apt']['components'] = [ '/' ]
default['go']['repository']['apt']['package_options'] = '--force-yes'
default['go']['repository']['apt']['keyserver'] = 'pgp.mit.edu'
default['go']['repository']['apt']['key'] = '0x9149B0A6173454C7'

default['go']['repository']['yum']['baseurl'] = 'http://download.go.cd/gocd-rpm'
default['go']['repository']['yum']['gpgcheck'] = false

version = node['go']['version']
case node['platform_family']
when 'debian'
  default['go']['server']['package_file']['filename'] = "go-server-#{version}.deb"
  default['go']['agent']['package_file']['filename'] = "go-agent-#{version}.deb"
  default['go']['package_file']['baseurl'] = 'http://download.go.cd/gocd-deb/'
when 'rhel','fedora'
  default['go']['server']['package_file']['filename'] = "go-server-#{version}.noarch.rpm"
  default['go']['agent']['package_file']['filename'] = "go-agent-#{version}.noarch.rpm"
  default['go']['package_file']['baseurl'] = 'http://download.go.cd/gocd-rpm/'
end

default['go']['server']['package_file']['path'] =
  File.join(Chef::Config[:file_cache_path], node['go']['server']['package_file']['filename'])
default['go']['server']['package_file']['url'] =
  "#{node['go']['package_file']['baseurl']}/#{node['go']['server']['package_file']['filename']}"
default['go']['agent']['package_file']['path'] =
  File.join(Chef::Config[:file_cache_path], node['go']['agent']['package_file']['filename'])
default['go']['agent']['package_file']['url'] =
  "#{node['go']['package_file']['baseurl']}/#{node['go']['agent']['package_file']['filename']}"
