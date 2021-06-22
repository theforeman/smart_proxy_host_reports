require 'test_helper'

class SpooledHttpClientTest < Test::Unit::TestCase
  def setup
    @foreman_url = "http://foreman.example.com"
    Proxy::SETTINGS.stubs(:foreman_url).returns(@foreman_url)
    Proxy::HostReports::Plugin.settings.stubs(:keep_reports).returns(true)
    @tmpdir = Dir.mktmpdir("spool-http-client-test")
    @client = SpooledHttpClient.new(@tmpdir)
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
    @client.spool("uuid", "something")
    assert assert_spool("todo", "uuid", "something")
  end

  def test_move_plain
    @client.spool("uuid", "something")
    @client.spool_move("todo", "done", "uuid")
    assert assert_spool("done", "uuid")
  end

  def test_process_plain
    stub_request(:post, @foreman_url + '/api/v2/host_reports').with(:body => "body").to_return(:status => [200, 'OK'], :body => "body")
    @client.spool("uuid", "body")
    @client.process
    assert assert_spool("done", "uuid")
  end

  def test_process_plain_two
    stub_request(:post, @foreman_url + '/api/v2/host_reports').with(:body => "body").to_return(:status => [200, 'OK'], :body => "body")
    @client.spool("uuid1", "body")
    @client.spool("uuid2", "body")
    @client.process
    assert assert_spool("done", "uuid1")
    assert assert_spool("done", "uuid2")
  end
end