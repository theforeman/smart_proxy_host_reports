require "test_helper"

class SpooledHttpClientTest < Test::Unit::TestCase
  def setup
    @foreman_url = "http://foreman.example.com"
    ::Proxy::SETTINGS.stubs(:foreman_url).returns(@foreman_url)
    ::Proxy::Reports::Plugin.settings.stubs(:keep_reports).returns(true)
    Proxy::Reports::SpooledHttpClient.any_instance.stubs(:unique_filename).returns("time")
    @tmpdir = Dir.mktmpdir("spool-http-client-test")
    @client = ::Proxy::Reports::SpooledHttpClient.instance.initialize_directory(@tmpdir)
  end

  def teardown
    FileUtils.rm_rf(@tmpdir) if @tmpdir
  end

  def print_spool
    Dir.glob("#{@tmpdir}/**/*") do |file|
      puts file
    end
  end

  def assert_spool(state, filename, contents = nil)
    file = File.join(@tmpdir, state, filename)
    return false unless File.exist? file
    return false if contents && contents != File.read(file)
    true
  end

  def test_spool_plain
    @client.spool(:report, "something")
    assert assert_spool("todo", "time-report", "something")
  end

  def test_move_plain
    @client.spool(:report, "something")
    @client.spool_move("todo", "done", "time-report")
    assert assert_spool("done", "time-report")
  end

  def test_process_plain
    stub_request(:post, @foreman_url + "/api/v2/host_reports").with(:body => "body").to_return(:status => [200, "OK"], :body => "body")
    @client.spool(:report, "body")
    @client.process
    assert assert_spool("done", "time-report")
  end

  def test_process_plain_two
    stub_request(:post, @foreman_url + "/api/v2/host_reports").with(:body => "body").to_return(:status => [200, "OK"], :body => "body")
    @client.spool(:report, "body")
    @client.spool(:report, "body")
    @client.process
    assert assert_spool("done", "time-report")
    assert assert_spool("done", "time-report")
  end

  def test_process_plain_facts
    stub_request(:post, @foreman_url + "/api/v2/hosts/facts").with(:body => "body").to_return(:status => [200, "OK"], :body => "body")
    @client.spool(:ansible_facts, "body")
    @client.process
    assert assert_spool("done", "time-ansible_facts")
  end

  def test_process_plain_two_facts
    stub_request(:post, @foreman_url + "/api/v2/hosts/facts").with(:body => "body").to_return(:status => [200, "OK"], :body => "body")
    @client.spool(:ansible_facts, "body")
    @client.spool(:ansible_facts, "body")
    @client.process
    assert assert_spool("done", "time-ansible_facts")
    assert assert_spool("done", "time-ansible_facts")
  end
end
