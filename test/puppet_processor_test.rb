require 'test_helper'

class PuppetProcessorTest < Test::Unit::TestCase
  def test_deb
    input = File.read(File.join(File.dirname(__FILE__), 'fixtures/foreman-deb.yaml'))
    processor = Processor.new_processor("puppet", input)
    result = processor.to_foreman
    assert_equal "puppet", result["format"]
    assert_equal "deb.example.com", result["host"]
    assert_equal 10, result["report_format"]
    assert_equal "6.16.0", result["puppet_version"]
    assert_equal ["notice", "//deb.example.com/Puppet","Applied catalog in 8.03 seconds"], result["logs"].first
    assert_equal 405, result["metrics"]["resources"]["values"].first[2]
    assert_equal 30, result["evaluation_times"].count
    assert_equal ["PuppetResourceFailed:Package[bzip2]", "PuppetHasFailure"], result["keywords"]
  end

  def test_dis
    input = File.read(File.join(File.dirname(__FILE__), 'fixtures/foreman-dis.yaml'))
    processor = Processor.new_processor("puppet", input)
    result = processor.to_foreman
    assert_equal "puppet", result["format"]
    assert_equal "dis.example.com", result["host"]
    assert_equal 10, result["report_format"]
    assert_equal "6.15.0", result["puppet_version"]
    assert_equal ["notice", "//dis.example.com/Puppet", "Applied catalog in 2.08 seconds"], result["logs"].first
    assert_equal 168, result["metrics"]["resources"]["values"].first[2]
    assert_equal 30, result["evaluation_times"].count
    assert_equal [], result["keywords"]
  end

  def test_jen
    input = File.read(File.join(File.dirname(__FILE__), 'fixtures/foreman-jen.yaml'))
    processor = Processor.new_processor("puppet", input)
    result = processor.to_foreman
    assert_equal "puppet", result["format"]
    assert_equal "jen.example.com", result["host"]
    assert_equal 11, result["report_format"]
    assert_equal "6.19.1", result["puppet_version"]
    assert_equal ["notice", "//jen.example.com/Puppet", "Applied catalog in 34.49 seconds"], result["logs"].first
    assert_equal 346, result["metrics"]["resources"]["values"].first[2]
    assert_equal 30, result["evaluation_times"].count
    assert_equal [], result["keywords"]
  end

  def test_old
    input = File.read(File.join(File.dirname(__FILE__), 'fixtures/foreman-old.yaml'))
    processor = Processor.new_processor("puppet", input)
    result = processor.to_foreman
    assert_equal "puppet", result["format"]
    assert_equal "old.example.com", result["host"]
    assert_equal 6, result["report_format"]
    assert_equal "4.10.12", result["puppet_version"]
    assert_equal ["notice", "Puppet", "Applied catalog in 0.06 seconds"], result["logs"].first
    assert_equal 7, result["metrics"]["resources"]["values"].first[2]
    assert_equal 7, result["evaluation_times"].count
    assert_equal [], result["keywords"]
  end

  def test_red
    input = File.read(File.join(File.dirname(__FILE__), 'fixtures/foreman-red.yaml'))
    processor = Processor.new_processor("puppet", input)
    result = processor.to_foreman
    assert_equal "puppet", result["format"]
    assert_equal "red.example.com", result["host"]
    assert_equal 11, result["report_format"]
    assert_equal "6.19.1", result["puppet_version"]
    assert_equal ["notice", "//red.example.com/Puppet", "Applied catalog in 14.33 seconds"], result["logs"].first
    assert_equal 400, result["metrics"]["resources"]["values"].first[2]
    assert_equal 30, result["evaluation_times"].count
    assert_equal ["PuppetIsOutOfSync"], result["keywords"]
  end

  def test_web
    input = File.read(File.join(File.dirname(__FILE__), 'fixtures/foreman-web.yaml'))
    processor = Processor.new_processor("puppet", input)
    result = processor.to_foreman
    assert_equal "puppet", result["format"]
    assert_equal "web.example.com", result["host"]
    assert_equal 11, result["report_format"]
    assert_equal "6.19.1", result["puppet_version"]
    assert_equal ["notice", "//web.example.com/Puppet", "Applied catalog in 8.08 seconds"], result["logs"].first
    assert_equal 539, result["metrics"]["resources"]["values"].first[2]
    assert_equal 30, result["evaluation_times"].count
    assert_equal [
      "PuppetHasCorrectiveChange",
      "PuppetHasSkips",
      "PuppetResourceFailed:File[mime_magic.conf]",
      "PuppetHasFailure",
      "PuppetHasChange"
    ], result["keywords"]
  end

  def test_web_snapshot
    input = File.read(File.join(File.dirname(__FILE__), 'fixtures/foreman-web.yaml'))
    processor = Processor.new_processor("puppet", input)
    result = processor.to_foreman
    snapshot_filename = 'snapshots/foreman-web.json'
    output_file = File.join(File.dirname(__FILE__), snapshot_filename)
    if File.exist? output_file
      output = File.read(output_file)
    else
      output = result
      File.write(output_file, JSON.pretty_generate(result))
    end
    diff_result = ::JsonDiff.diff(JSON.parse(File.read(output_file), quirks_mode: true), result)
    unless diff_result.empty?
      fail "\nError in JSON diff for #{snapshot_filename}, review and delete it to generate:\n#{JSON.pretty_generate(diff_result)}\n"
    end
  end
end
