# frozen_string_literal: true
require 'proxy/log'

class Processor
  include ::Proxy::Log

  def self.new_processor(format, data)
    case format
    when 'puppet'
      PuppetProcessor.new(data)
    else
      NotImplementedError.new
    end
  end

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

  def to_foreman_as_json
    result = measure :format do
      to_foreman.to_json
    end
    logger.debug "Finished report #{report_id}: #{telemetry_as_string}"
    result
  end
end