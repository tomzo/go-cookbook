package_path = File.join(Chef::Config[:file_cache_path],go_agent_package_name)

remote_file go_agent_package_name do
  path package_path
  source go_agent_package_url
end

autoregister_values = get_agent_properties

if autoregister_values[:go_server_host].nil?
  autoregister_values[:go_server_host] = '127.0.0.1'
  Chef::Log.warn("Go server not found on Chef server or not specifed via node['gocd']['agent']['go_server_host'] attribute, defaulting Go server to #{autoregister_values[:go_server_host]}")
end

opts = []
opts << "/SERVERIP=#{autoregister_values[:go_server_host]}"
opts << "/S"
opts << '/D=C:\GoAgent'

execute "install Go Agent" do
  command "#{package_path} #{opts.join(' ')}"
  creates "C:\\GoAgent\\agent.cmd"
end
