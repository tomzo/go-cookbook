package_path = File.join(Chef::Config[:file_cache_path],go_server_package_name)

remote_file go_server_package_name do
  path package_path
  source go_server_package_url
end

opts = []
opts << '/S'
opts << '/D=C:\GoServer'

if defined?(Chef::Provider::Package::Windows)
  package 'Go Server' do
    installer_type :custom
    source package_path
    options opts.join(" ")
  end
else
  windows_package 'Go Server' do
    installer_type :custom
    source package_path
    options opts.join(" ")
  end
end
