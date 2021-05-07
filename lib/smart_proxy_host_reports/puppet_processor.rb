# frozen_string_literal: true
require 'proxy/log'

class PuppetProcessor
  include ::Proxy::Log

  YAML_CLEAN = /!ruby\/object.*$/.freeze
  KEYS_TO_COPY = %w[report_format puppet_version environment metrics].freeze
  MAX_EVAL_TIMES = 29

  def initialize(data)
    @data = YAML.safe_load(data.gsub(YAML_CLEAN,''), permitted_classes: [Symbol, Time, Date])
    @result = {}
    @evaluation_times = []
    @keywords_set = {}
    @errors = []
    logger.debug "Processing report #{report_id}"
    logger.debug(@data) if debug_payload?
  end

  def debug_payload?
    Proxy::HostReports::Plugin.settings.debug_payload
  end

  def report_id
    @data['transaction_uuid'] || SecureRandom.uuid
  end

  def add_keywords(*keywords)
    keywords.each do |keyword|
      @keywords_set[keyword] = true
    end
  end

  def process_logs
    logs = []
    @data["logs"]&.each do |log|
      logs << [log['level']&.to_s, log['source'], log['message']]
    end
    logs
  rescue StandardError => e
    logger.error "Unable to parse logs", e
    logs
  end

  def process_resource_statuses
    statuses = []
    @data["resource_statuses"]&.each_pair do |key, value|
      statuses << key
      @evaluation_times << [key, value['evaluation_time']]
      # failures
      add_keywords("PuppetResourceFailed:#{key}", "PuppetHasFailure") if value['failed'] || value['failed_to_restart']
      value['events']&.each do |event|
        add_keywords("PuppetResourceFailed:#{key}", "PuppetHasFailure") if event['status'] == 'failed'
        add_keywords("PuppetHasCorrectiveChange") if event['corrective_change']
      end
      # changes
      add_keywords("PuppetHasChange") if value['changed']
      add_keywords("PuppetHasChange") if value['change_count'] && value['change_count'] > 0
      # changes
      add_keywords("PuppetIsOutOfSync") if value['out_of_sync']
      add_keywords("PuppetIsOutOfSync") if value['out_of_sync_count'] && value['out_of_sync_count'] > 0
      # skips
      add_keywords("PuppetHasSkips") if value['skipped']
      # corrective changes
      add_keywords("PuppetHasCorrectiveChange") if value['corrective_change']
    end
    statuses
  rescue StandardError => e
    logger.error "Unable to parse resource_statuses", e
    statuses
  end

  def process_evaluation_times
    @evaluation_times.sort!{|a, b| b[1] <=> a[1]}
    if @evaluation_times.count > MAX_EVAL_TIMES
      others = @evaluation_times[MAX_EVAL_TIMES..@evaluation_times.count-1].sum{|x| x[1]}
      @evaluation_times = @evaluation_times[0..MAX_EVAL_TIMES-1]
      @evaluation_times << ["Others", others] if others > 0.0001
    end
    @evaluation_times
  rescue StandardError => e
    logger.error "Unable to process evaluation_times", e
    []
  end

  def to_foreman
    @result['format'] = 'puppet'
    @result['id'] = report_id
    @result['host'] = @data['host']
    @result['proxy'] = Proxy::HostReports::Plugin.settings.reported_proxy_hostname
    @result['reported_at'] = @data['time']
    KEYS_TO_COPY.each do |key|
      @result[key] = @data[key]
    end
    @result['logs'] = process_logs
    @result['resource_statuses'] = process_resource_statuses
    @result['keywords'] = @keywords_set.keys.to_a
    @result['evaluation_times'] = process_evaluation_times
    @result['errors'] = @errors unless @errors.empty?
    if debug_payload?
      logger.debug { JSON.pretty_generate(@result) }
    end
    @result
  end
end