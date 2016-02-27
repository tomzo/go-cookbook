require 'spec_helper'

describe 'gocd::agent' do
  shared_examples_for :agent_recipe_windows do
    it 'configures go-agent service' do
      expect(chef_run).to enable_service('Go Agent')
      expect(chef_run).to start_service('Go Agent')
    end
  end

  context 'When all attributes are default and platform is windows' do
    it_behaves_like :agent_recipe_windows
    let(:chef_run) do
      run = ChefSpec::SoloRunner.new(step_into: 'gocd_agent') do |node|
        node.automatic['platform_family'] = 'windows'
        node.automatic['platform'] = 'windows'
        node.automatic['os'] = 'windows'
      end
      run.converge(described_recipe)
    end

    it 'downloads official installer' do
      expect(chef_run).to create_remote_file('go-agent-stable-setup.exe').with(
        :source => 'https://download.go.cd/binaries/16.2.1-3027/win/go-agent-16.2.1-3027-setup.exe')
    end
    it 'installs package via execute' do
      expect(chef_run).to run_execute('install Go Agent')
    end
  end

  context 'When installing from custom url and platform is windows' do
    it_behaves_like :agent_recipe_windows
    let(:chef_run) do
      run = ChefSpec::SoloRunner.new(step_into: 'gocd_agent') do |node|
        node.automatic['platform_family'] = 'windows'
        node.automatic['platform'] = 'windows'
        node.automatic['os'] = 'windows'
        node.normal['gocd']['agent']['package_file']['url'] = 'https://example.com/go-agent.exe'
      end
      run.converge(described_recipe)
    end
    it 'downloads specified installer' do
      expect(chef_run).to create_remote_file('go-agent-custom-setup.exe').with(
        :source => 'https://example.com/go-agent.exe')
    end
    it 'installs package via execute' do
      expect(chef_run).to run_execute('install Go Agent')
    end
  end
end
