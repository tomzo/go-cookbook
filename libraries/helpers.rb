module Gocd
  module Helpers
    def get_agent_properties
      values = {}
      values[:go_server_port]   = node['gocd']['agent']['go_server_port']
      if Chef::Config['solo'] || node['gocd']['agent']['go_server_host']
        Chef::Log.info("Attempting to use node['gocd']['agent']['go_server_host'] attribute for server host")
        values[:go_server_host]   = node['gocd']['agent']['go_server_host']
        values[:key] = node['gocd']['agent']['autoregister']['key']
      else
        server_search_query = node['gocd']['agent']['server_search_query']
        Chef::Log.info("Search query: #{server_search_query}")
        go_servers = search(:node, server_search_query)
        if go_servers.count == 0
          Chef::Log.warn("No Go servers found on any of the nodes running chef client.")
        else
          go_server = go_servers.first
          values[:go_server_host] = go_server['ipaddress']
          if go_servers.count > 1
            Chef::Log.warn("Multiple Go servers found on Chef server. Using first returned server '#{values[:go_server_host]}' for server instance configuration.")
          end
          Chef::Log.info("Found Go server at ip address #{values[:go_server_host]} with automatic agent registration")
          if values[:key] = go_server['gocd']['server']['autoregister_key']
            Chef::Log.warn("Agent auto-registration enabled. This agent will not require approval to become active.")
          end
        end
      end
      values[:hostname]     = node['gocd']['agent']['autoregister']['hostname']
      values[:environments] = node['gocd']['agent']['autoregister']['environments']
      values[:resources]    = node['gocd']['agent']['autoregister']['resources']
      values[:daemon]       = node['gocd']['agent']['daemon']
      values[:vnc]          = node['gocd']['agent']['vnc']['enabled']
      values[:workspace]    = node['gocd']['agent']['workspace']
      values
    end

    def go_server_config_file
      if platform?('windows')
        'C:\Program Files\Go Server\config\cruise-config.xml'
      else
        '/etc/go/cruise-config.xml'
      end
    end

    def go_version
      if node['gocd']['version']
        # user explictly requested Go version
        node['gocd']['version']
      elsif node['platform_family'] == 'windows'
        # we are on windows, so there is no repository to tell what is 'latest'
        # but we can ask go updates service
        fetch_go_version 'stable'
      else
        'stable'
      end
    end
    # version to pass into 'package' resource
    def go_version_repo
      # just return attribute value, when nil it will default to installing stable
      node['gocd']['version']
    end

    # Only needed when downloading package from URL
    def remote_version
      version = go_version
      if version == 'stable' || version == 'supported' || version == 'experimental'
        fetch_go_version version
      elsif version.nil?
        fetch_go_version 'stable'
      else
        version
      end
    end

    def updates_base_feed
      node['gocd']['updates']['baseurl']
    end

    def fetch_go_version name
      require 'net/http'
      require 'uri'
      case name
      when 'stable', :stable, 'supported', :supported
        # https://update.go.cd/channels/supported/latest.json
        url = "#{updates_base_feed}/supported/latest.json"
      when 'experimental', :experimental
        # https://update.go.cd/channels/experimental/latest.json
        url = "#{updates_base_feed}/experimental/latest.json"
      else
        fail "Invalid version name '#{name}' - must be stable (supported) or experimental"
      end
      begin
        json = Net::HTTP.get(URI.parse(url))
        parsed = JSON.parse(json)
        fail 'Invalid format in version json file' unless parsed['message']
        message = JSON.parse(parsed['message'])
        return message['latest-version']
      rescue Exception => e
        Chef::Log.error("Failed to get Go version from updates service - #{e}")
        # fallback to last known stable
        '16.2.1-3027'
      end
    end

    def package_extension
      case node['platform_family']
      when 'debian'
        ".deb"
      when 'rhel', 'fedora'
        ".noarch.rpm"
      when 'windows'
        "-setup.exe"
      else
        ".zip"
      end
    end

    def os_dir
      case node['platform_family']
      when 'debian'
        'deb'
      when 'rhel', 'fedora'
        'rpm'
      when 'windows'
        'win'
      else
        "generic"
      end
    end

    def go_agent_remote_package_name
      "go-agent-#{remote_version}#{package_extension}"
    end
    def go_server_remote_package_name
      "go-server-#{remote_version}#{package_extension}"
    end

    def user_friendly_agent_version
      if node['gocd']['version']
        return node['gocd']['version']
      elsif node['gocd']['agent']['package_file']['url']
        return 'custom'
      else
        return 'stable'
      end
    end
    def user_friendly_server_version
      if node['gocd']['version']
        return node['gocd']['version']
      elsif node['gocd']['server']['package_file']['url']
        return 'custom'
      else
        return 'stable'
      end
    end

    # user-friendly file names to use when downloading remote file
    def go_agent_package_name
      "go-agent-#{user_friendly_agent_version}#{package_extension}"
    end
    def go_server_package_name
      "go-server-#{user_friendly_server_version}#{package_extension}"
    end

    def go_baseurl
      if node['gocd']['package_file']['baseurl']
        # user specifed url to download packages from
        node['gocd']['package_file']['baseurl']
      else
        # use official source
        "https://download.go.cd/binaries"
      end
    end

    def go_agent_package_url
      if node['gocd']['agent']['package_file']['url']
        # user specifed explictly the URL to download from
        node['gocd']['agent']['package_file']['url']
      else
        "#{go_baseurl}/#{remote_version}/#{os_dir}/#{go_agent_remote_package_name}"
      end
    end
    def go_server_package_url
      if node['gocd']['server']['package_file']['url']
        # user specifed explictly the URL to download from
        node['gocd']['server']['package_file']['url']
      else
        "#{go_baseurl}/#{remote_version}/#{os_dir}/#{go_server_remote_package_name}"
      end
    end
  end
end

Chef::Recipe.send(:include, ::Gocd::Helpers)
Chef::Resource.send(:include, ::Gocd::Helpers)
Chef::Provider.send(:include, ::Gocd::Helpers)
