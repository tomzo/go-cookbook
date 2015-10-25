require 'spec_helper'

describe 'gocd::agent' do
  shared_examples_for :agent_recipe do
    it 'includes java recipe' do
      expect(chef_run).to include_recipe('java::default')
    end
    it 'creates go agent configuration in /etc/default/go-agent' do
      expect(chef_run).to render_file('/etc/default/go-agent').with_content { |content|
        expect(content).to_not include('java-6')
      }
    end
    it 'configures go-agent service' do
      expect(chef_run).to enable_service('go-agent')
      expect(chef_run).to start_service('go-agent')
    end
  end

  context 'When all attributes are default and platform is debian' do
    let(:chef_run) do
      run = ChefSpec::SoloRunner.new do |node|
        node.automatic['lsb']['id'] = 'Debian'
        node.automatic['platform_family'] = 'debian'
        node.automatic['platform'] = 'debian'
        node.automatic['os'] = 'linux'
      end
      run.converge(described_recipe)
    end
    it_behaves_like :agent_recipe
    it_behaves_like :apt_repository_recipe
    it 'installs go-agent package' do
      expect(chef_run).to install_package('go-agent')
    end
  end
  context 'When all attributes are default and platform is centos' do
    let(:chef_run) do
      run = ChefSpec::SoloRunner.new do |node|
        node.automatic['platform_family'] = 'rhel'
        node.automatic['platform'] = 'centos'
        node.automatic['os'] = 'linux'
      end
      run.converge(described_recipe)
    end
    it_behaves_like :agent_recipe
    it_behaves_like :yum_repository_recipe
    it 'installs go-agent package' do
      expect(chef_run).to install_package('go-agent')
    end
  end
  #TODO: agent on windows

  context 'When installing from package_file and platform is debian' do
    let(:chef_run) do
      run = ChefSpec::SoloRunner.new do |node|
        node.automatic['lsb']['id'] = 'Debian'
        node.automatic['platform_family'] = 'debian'
        node.automatic['platform'] = 'debian'
        node.automatic['os'] = 'linux'
        node.normal['gocd']['install_method'] = 'package_file'
      end
      run.converge(described_recipe)
    end
    it_behaves_like :agent_recipe
    it 'downloads go-agent .deb from remote URL' do
      expect(chef_run).to create_remote_file('go-agent-15.2.0-2248.deb').with(
        source: 'http://download.go.cd/gocd-deb/go-agent-15.2.0-2248.deb')
    end
    it 'installs go-agent package from file' do
      expect(chef_run).to install_dpkg_package('go-agent')
    end
  end
  context 'When installing from package file and platform is centos' do
    let(:chef_run) do
      run = ChefSpec::SoloRunner.new do |node|
        node.automatic['platform_family'] = 'rhel'
        node.automatic['platform'] = 'centos'
        node.automatic['os'] = 'linux'
        node.normal['gocd']['install_method'] = 'package_file'
      end
      run.converge(described_recipe)
    end
    it_behaves_like :agent_recipe
    it 'downloads go-agent .rpm from remote URL' do
      expect(chef_run).to create_remote_file('go-agent-15.2.0-2248.noarch.rpm').with(
        source: 'http://download.go.cd/gocd-rpm/go-agent-15.2.0-2248.noarch.rpm')
    end
    it 'installs go-agent package from file' do
      expect(chef_run).to install_rpm_package('go-agent')
    end
  end

  context 'When installing from custom repository and platform is debian' do
    let(:chef_run) do
      run = ChefSpec::SoloRunner.new do |node|
        node.automatic['lsb']['id'] = 'Debian'
        node.automatic['platform_family'] = 'debian'
        node.automatic['platform'] = 'debian'
        node.automatic['os'] = 'linux'
        node.normal['gocd']['install_method'] = 'repository'
        node.normal['gocd']['repository']['apt']['uri'] = 'http://mydeb/repo'
        node.normal['gocd']['repository']['apt']['components'] = [ '/' ]
        node.normal['gocd']['repository']['apt']['package_options'] = '--force-yes'
        node.normal['gocd']['repository']['apt']['keyserver'] = false
        node.normal['gocd']['repository']['apt']['key'] = false
      end
      run.converge(described_recipe)
    end
    it_behaves_like :agent_recipe
    it 'includes apt recipe' do
      expect(chef_run).to include_recipe('apt')
    end
    it 'adds my custom gocd apt repository' do
      expect(chef_run).to add_apt_repository('gocd').with(
        uri: 'http://mydeb/repo',
        keyserver: nil,
        key: nil,
        components: ['/'])
    end
    it 'installs go-agent package' do
      expect(chef_run).to install_package('go-agent')
    end
  end
  context 'When installing from custom repository and platform is centos' do
    let(:chef_run) do
      run = ChefSpec::SoloRunner.new do |node|
        node.automatic['platform_family'] = 'rhel'
        node.automatic['platform'] = 'centos'
        node.automatic['os'] = 'linux'
        node.normal['gocd']['install_method'] = 'repository'
        node.normal['gocd']['repository']['yum']['baseurl'] = 'http://mycustom/gocd-rpm'
      end
      run.converge(described_recipe)
    end
    it_behaves_like :agent_recipe
    it 'includes yum recipe' do
      expect(chef_run).to include_recipe('yum')
    end
    it 'adds my custom gocd yum repository' do
      expect(chef_run).to create_yum_repository('gocd').with(
        baseurl: 'http://mycustom/gocd-rpm',
        gpgcheck: false
      )
    end
    it 'installs go-agent package' do
      expect(chef_run).to install_package('go-agent')
    end
  end
end