# Cookbook Name:: go
# Recipe:: agent_linux

include_recipe 'go::repository'

include_recipe 'java'

go_server_autoregister  = node['go']['agent']['auto_register']
autoregister_key        = node['go']['agent']['auto_register_key']
server_search_query     = node['go']['agent']['server_search_query']

case node['go']['install_method']
when 'repository'
  include_recipe 'go::repository'
  package_options = node['go']['repository']['apt']['package_options'] if node['platform_family'] == 'debian'
  package "go-agent" do
    version node['go']['version']
    options package_options
  end
when 'package_file'
  remote_file node['go']['agent']['package_file']['filename'] do
    path node['go']['agent']['package_file']['path']
    source node['go']['agent']['package_file']['url']
    mode 0644
  end
  case node['platform_family']
  when 'debian'
    dpkg_package 'go-agent' do
      source node['go']['agent']['package_file']['path']
    end
  when 'rhel','fedora'
    rpm_package 'go-agent' do
      source node['go']['agent']['package_file']['path']
    end
  end
else
  fail "Unknown install method - '#{node['go']['install_method']}'"
end

# If running under solo or user specifed the server host, try and use that
if Chef::Config['solo'] || node['go']['agent'].attribute?('server_host')
  Chef::Log.info("Attempting to use node['go']['agent']['server_host'] attribute " +
    "for server host")
  go_server_host = node['go']['agent']['server_host']
else
  # Running under client and user didn't specify a server_host attribute
  Chef::Log.info("Search query: #{server_search_query}")
  go_servers = search(:node, server_search_query)
  if go_servers.count == 0
    Chef::Log.warn("No Go servers found on Chef server.")
  else
    go_server = go_servers[0]
    go_server_host = go_server['ipaddress']
    if go_servers.count > 1
      Chef::Log.warn("Multiple Go servers found on Chef server. Using first returned server " +
        "'#{go_server_host}' for server instance configuration.")
    end
    go_server_autoregister = go_server['go']['auto_register_agents']
    Chef::Log.info("Found Go server at ip address #{go_server_host} with automatic agent registration=#{go_server_autoregister}")
    if (go_server_autoregister)
      Chef::Log.warn("Agent auto-registration enabled.  This agent will not require approval to become active.")
      autoregister_key = go_server['go']['autoregister_key']
    else
      autoregister_key = ""
    end
  end
end

# Ensure we have a Go server host set to a sensible default
if go_server_host.nil?
  go_server_host = '127.0.0.1'
  Chef::Log.warn("Go server not found on Chef server or not specifed via " +
    "node['go']['agent']['server_host'] attribute, defaulting Go server to #{go_server_host}")
end


# Install & configure the initial (default) Go agent as it comes from the binary distribution
# Then install any additional agents with -COUNT addition.
# i.e.
# /etc/default/go-agent
#             /go-agent-2
#             /go-agent-3
# /var/lib/go-agent
#         /go-agent-2
#         /go-agent-3
#
# default['go']['agent'][:instance_count] = node[:cpu][:total]

(1..node['go']['agent']['instance_count']).each do |i|
  log "Configuring Go agent # #{i} of #{node['go']['agent']['instance_count']} for Go server at #{go_server_host}:8153 "
  if (i < 2)
    suffix = ""
  else
    suffix = "-#{i}"
  end

  template "/etc/init.d/go-agent#{suffix}" do
    # <%= @go_agent_instance -%>
    source 'go-agent-service.erb'
    mode '0755'
    owner 'root'
    group 'root'
    variables(:go_agent_instance => suffix)
  end

  if node['go']['agent']['daemon']
    daemon = 'Y'
  else
    daemon = 'N'
  end
  template "/etc/default/go-agent#{suffix}" do
    source 'go-agent-defaults.erb'
    mode '0644'
    owner 'go'
    group 'go'
    variables(:go_server_host => go_server_host,
      :go_server_port => '8153',
      :java_home => node['java']['java_home'],
      :daemon => daemon,
      :work_dir => "#{node['go']['agent']['work_dir_path']}/go-agent#{suffix}")
  end

  template "/usr/share/go-agent/agent#{suffix}.sh" do
    source 'go-agent-sh.erb'
    mode '0755'
    owner 'go'
    group 'go'
    variables(:go_agent_instance => suffix)
  end

  log "Registering agent#{suffix} with autoregister key of " + autoregister_key

  directory "/var/log/go-agent#{suffix}" do
    mode '0755'
    owner 'go'
    group 'go'
  end

  directory "/var/lib/go-agent#{suffix}" do
    mode '0755'
    owner 'go'
    group 'go'
  end

  directory "/var/lib/go-agent#{suffix}/config" do
    mode '0755'
    owner 'go'
    group 'go'
  end

  autoregister_resources = []
  node['go']['agent']['auto_register_resources'].each do |resource_key|
    autoregister_resources.push(resource_key)
  end

  autoregister_environments = []
  node['go']['agent']['auto_register_environments'].each do |env_key|
    autoregister_environments.push(env_key)
  end

  autoregister_resources.push(node['os'], node['platform'], "#{node['platform']}-#{node['platform_version']}")

  log "Registering agent with resource tags: #{autoregister_resources} and environments: #{autoregister_environments}"

  template "/var/lib/go-agent#{suffix}/config/autoregister.properties" do
    source 'autoregister.properties.erb'
    mode '0644'
    group 'go'
    owner 'go'
    variables(
      :autoregister_key => autoregister_key,
      :agent_resources => autoregister_resources.join(","),
      :agent_environments => autoregister_environments.join(","))
  end

  if node['go']['agent']['manage_service']
    service "go-agent#{suffix}" do
      supports :status => true, :restart => true, :reload => true, :start => true
      action :nothing
      subscribes :enable, "template[/etc/init.d/go-agent#{suffix}]"
      subscribes :enable, "template[/var/lib/go-agent#{suffix}/config/autoregister.properties]"
      subscribes :enable, "template[/etc/default/go-agent#{suffix}]"
      subscribes :restart, "template[/etc/init.d/go-agent#{suffix}]"
      subscribes :restart, "template[/var/lib/go-agent#{suffix}/config/autoregister.properties]"
      subscribes :restart, "template[/etc/default/go-agent#{suffix}]"
    end
  end
end
