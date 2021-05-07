require 'test_helper'
require 'json'
require 'root/root_v2_api'

class HostReportsRootIntegrationTest < ::Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Proxy::PluginInitializer.new(Proxy::Plugins.instance).initialize_plugins
    Proxy::RootV2Api.new
  end

  def test_features
    plugin_settings = {
      enabled: true
    }

    Proxy::DefaultModuleLoader.any_instance.expects(:load_configuration_file).with('host_reports.yml').returns(plugin_settings)

    get '/features'

    response = JSON.parse(last_response.body)

    mod = response['host_reports']
    refute_nil(mod)
    assert_equal('running', mod['state'], Proxy::LogBuffer::Buffer.instance.info[:failed_modules][:externalipam])
    assert_equal([], mod['capabilities'])
  end
end
