require "test_helper"

class ReportsIntegrationTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Proxy::Reports::Api.new
  end

  def test_without_content_type_and_format
    post "/"
    assert_equal 404, last_response.status
  end

  def test_without_content_type
    post "/puppet"
    assert_equal 415, last_response.status
  end

  def test_without_format
    post "/", nil, { "CONTENT_TYPE" => "application/x-yaml" }
    assert_equal 404, last_response.status
  end

  def test_empty_puppet
    post "/puppet", nil, { "CONTENT_TYPE" => "application/x-yaml" }
    assert_equal 415, last_response.status
  end

  def test_invalid_puppet
    post "/puppet", "", { "CONTENT_TYPE" => "application/x-yaml" }
    assert_equal 415, last_response.status
  end

  def test_valid_puppet
    SpooledHttpClient.instance.expects(:spool)
    yaml = File.read(File.join(File.dirname(__FILE__), "fixtures/puppet6-foreman-old.yaml"))
    post "/puppet", yaml, { "CONTENT_TYPE" => "application/x-yaml" }
    assert_equal "", last_response.body
    assert_equal 200, last_response.status
  end
end
