require "test_helper"

class AnsibleProcessorTest < Test::Unit::TestCase
  def setup
    Proxy::Reports::Plugin.settings.stubs(:reported_proxy_hostname).returns("localhost")
  end

  def test_keys_are_strings
    processor = setup_processor("ansible", "ansible-copy-nochange.json")
    report = processor.build_report
    assert check_hash_keys(report), "All keys are strings: #{report.inspect}"
  end

  Dir.glob(File.join(__dir__, "fixtures", "ansible*json")).each do |fixture_filename|
    fixture_filename = File.basename(fixture_filename.tr("- ", "--"))
    define_method("test_snapshot_#{fixture_filename}") do
      processor = setup_processor("ansible", fixture_filename)
      result = processor.build_report
      remove_volatile_keys(result)
      snapshot_filename = File.join(__dir__, "snapshots", "#{File.basename(fixture_filename)}.snapshot.json")
      assert_snapshot(result, snapshot_filename)
    end
  end
end
