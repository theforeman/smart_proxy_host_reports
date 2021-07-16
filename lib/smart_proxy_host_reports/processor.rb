# frozen_string_literal: true
require "pp"
require "proxy/log"

# TODO: move everything into a module

class Processor
  include ::Proxy::Log

  def self.new_processor(format, data)
    case format
    when "puppet"
      PuppetProcessor.new(data)
    else
      NotImplementedError.new
    end
  end

  def initialize(*)
    @keywords_set = {}
    @errors = []
  end

  def build_report_root(format:, version:, host:, reported_at:, status:, proxy:, body:, keywords:)
    {
      "host_report" => {
        "format" => format,
        "version" => version,
        "host" => host,
        "reported_at" => reported_at,
        "status" => status,
        "proxy" => proxy,
        "body" => body,
        "keywords" => keywords,
      },
    }
    # TODO add body string serialization and metric with total time
    # and for tests there must be an option to turn this off
  end

  def debug_payload?
    Proxy::HostReports::Plugin.settings.debug_payload
  end

  def debug_payload(prefix, data)
    return unless debug_payload?
    logger.debug { "#{prefix}: #{data.pretty_inspect}" }
  end

  def add_keywords(*keywords)
    keywords.each do |keyword|
      @keywords_set[keyword] = true
    end
  end

  def keywords
    @keywords_set.keys.to_a rescue []
  end

  attr_reader :errors

  def log_error(message)
    @errors << message.to_s
  end

  def errors?
    @errors&.any?
  end

  # TODO support multiple metrics and adding total time
  attr_reader :telemetry

  def measure(metric)
    t1 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    yield
  ensure
    t2 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    @telemetry ||= {}
    @telemetry[metric] = (t2 - t1) * 1000
  end

  def telemetry_as_string
    result = []
    telemetry.each do |key, value|
      result << "#{key}=#{value.round(1)}ms"
    end
    result.join(", ")
  end

  def spool_report
    super
    logger.debug "Spooled #{report_id}: #{telemetry_as_string}"
  end
end
