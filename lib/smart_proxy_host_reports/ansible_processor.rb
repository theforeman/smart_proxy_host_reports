# frozen_string_literal: true

class AnsibleProcessor < Processor
  def initialize(data)
    super(data)
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
    # TODO: find keywords
  rescue StandardError => e
    logger.error "Unable to parse logs", e
  end

  def process
    measure :process do
      process_logs
      @body["format"] = "ansible"
      @body["id"] = report_id
      @body["host"] = hostname_from_config || @data["host"]
      @body["proxy"] = Proxy::HostReports::Plugin.settings.reported_proxy_hostname
      @body["reported_at"] = @data["reported_at"]
      @body["logs"] = @data["logs"]
      @body["keywords"] = keywords
      @body["telemetry"] = telemetry
      @body["errors"] = errors if errors?
    end
  end

  def build_report
    process
    if debug_payload?
      logger.debug { JSON.pretty_generate(@body) }
    end
    report = build_report_root(
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
end
