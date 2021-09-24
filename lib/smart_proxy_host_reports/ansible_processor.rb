# frozen_string_literal: true

class AnsibleProcessor < Processor
  KEYS_TO_COPY = %w[status check_mode].freeze

  def initialize(data, json_body: true)
    super(data, json_body: json_body)
    measure :parse do
      @data = JSON.parse(data)
    end
    @body = {}
    logger.debug "Processing report #{report_id}"
    debug_payload("Input", @data)
  end

  def report_id
    @data["uuid"] || generated_report_id
  end

  def process_logs
    logs = []
    @data["logs"]&.each do |log|
      logs << [log_level(log), log_source(log), log_message(log)]
      process_keywords(log)
    end
    logs
  rescue StandardError => e
    logger.error "Unable to parse logs", e
    logs
  end

  def process_keywords(log)
    if log["failed"]
      add_keywords("HasFailure")
    elsif log["changed"]
      add_keywords("HasChange")
    end
  end

  def process
    measure :process do
      @body["format"] = "ansible"
      @body["id"] = report_id
      @body["host"] = hostname_from_config || @data["host"]
      @body["proxy"] = Proxy::HostReports::Plugin.settings.reported_proxy_hostname
      @body["reported_at"] = @data["reported_at"]
      @body["logs"] = process_logs
      @body["keywords"] = keywords
      @body["telemetry"] = telemetry
      @body["errors"] = errors if errors?
      KEYS_TO_COPY.each do |key|
        @body[key] = @data[key]
      end
    end
  end

  def build_report
    process
    if debug_payload?
      logger.debug { JSON.pretty_generate(@body) }
    end
    build_report_root(
      format: "ansible",
      version: 1,
      host: @body["host"],
      reported_at: @body["reported_at"],
      status: 0,
      proxy: @body["proxy"],
      body: @body,
      keywords: @body["keywords"],
    )
  end

  def spool_report
    report_hash = build_report
    debug_payload("Output", report_hash)
    payload = measure :format do
      report_hash.to_json
    end
    SpooledHttpClient.instance.spool(report_id, payload)
  end

  private

  def log_level(log)
    if log["failed"]
      "err"
    elsif log["changed"]
      "notice"
    else
      "info"
    end
  end

  def log_source(log)
    # Temporary until  is resolved
    log["module"]
  end

  def log_message(log)
    return log["msg"] if log["failed"]

    case log["module"]
    when "package"
      log["results"].empty? ? log["msg"] : log["results"]
    when "template"
      module_args = log["invocation"]["module_args"]
      "Rendered template #{module_args["_original_basename"]} to #{log["dest"]}"
    when "service"
      "Service #{log["name"]} #{log["state"]} (enabled: #{log["enabled"]})"
    when "group"
      "User group #{log["name"]} #{log["state"]}, gid: #{log["gid"]}"
    when "user"
      "User #{log["name"]} #{log["state"]}, uid: #{log["uid"]}"
    when "cron"
      module_args = log["invocation"]["module_args"]
      "Cron job: #{module_args["minute"]} #{module_args["hour"]} #{module_args["day"]} #{module_args["month"]} #{module_args["weekday"]} #{module_args["job"]} (disabled: #{module_args["disabled"]})"
    when "copy"
      module_args = log["invocation"]["module_args"]
      "Copy #{module_args["_original_basename"]} to #{log["dest"]}"
    when "command", "shell"
      log["stdout_lines"]
    else
      "No additional data"
    end
  end
end
