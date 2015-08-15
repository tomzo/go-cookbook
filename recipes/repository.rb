case node['platform_family']
when 'debian'
  include_recipe 'apt'

  apt_repository 'thoughtworks' do
    uri node['go']['repository']['apt']['uri']
    keyserver node['go']['repository']['apt']['keyserver']
    key node['go']['repository']['apt']['key']
    components node['go']['repository']['apt']['components']
  end
when 'rhel','fedora'
  include_recipe 'yum'
  yum_repository 'thoughtworks' do
    baseurl node['go']['repository']['yum']['baseurl']
    gpgcheck node['go']['repository']['yum']['gpgcheck']
  end
end
