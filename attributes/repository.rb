default['gocd']['version'] = nil  # can be `latest` or specify a version `X.Y.Z-ABCD`
default['gocd']['use_experimental'] = false

if node['platform_family'] == 'windows'
  default['gocd']['install_method'] = 'package_file'
else
  default['gocd']['install_method'] = 'repository'
end

default['gocd']['updates']['url'] = nil

default['gocd']['repository']['apt']['components'] = ['/']
default['gocd']['repository']['apt']['distribution'] = ''
default['gocd']['repository']['apt']['package_options'] = ''
default['gocd']['repository']['apt']['keyserver'] = 'pgp.mit.edu'
default['gocd']['repository']['apt']['key'] = '0xd8843f288816c449'

default['gocd']['repository']['yum']['gpgcheck'] = true
default['gocd']['repository']['yum']['gpgkey'] = 'https://download.go.cd/GOCD-GPG-KEY.asc'

default['gocd']['package_file']['baseurl'] = nil # official - "https://download.go.cd/binaries"
default['gocd']['agent']['package_file']['url'] = nil # official
default['gocd']['server']['package_file']['url'] = nil # official
