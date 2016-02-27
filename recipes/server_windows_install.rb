package_path = File.join(Chef::Config[:file_cache_path],go_server_package_name)

remote_file go_server_package_name do
  path package_path
  source go_server_package_url
end

opts = []
opts << '/S'
opts << '/D=C:\GoServer'

execute "install Go Server" do
  command "#{package_path} #{opts.join(' ')}"
  creates "C:\\GoServer"
end
