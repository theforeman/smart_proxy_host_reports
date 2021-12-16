# frozen_string_literal: true

require_relative "friendly_message"

module Proxy::Reports
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

    def process_results
      @data["results"]&.each do |result|
        raise("Report do not contain required 'results/result' element") unless result["result"]
        raise("Report do not contain required 'results/task' element") unless result["task"]
        process_facts(result)
        process_level(result)
        friendly_message = FriendlyMessage.new(result)
        result["friendly_message"] = friendly_message.generate_message
        process_keywords(result)
      end
      @data["results"]
    rescue StandardError => e
      logger.error "Unable to parse results", e
      @data["results"]
    end

    def process
      measure :process do
        @body["format"] = "ansible"
        @body["id"] = report_id
        @body["host"] = hostname_from_config || @data["host"]
        @body["proxy"] = Proxy::Reports::Plugin.settings.reported_proxy_hostname
        @body["reported_at"] = @data["reported_at"]
        @body["results"] = process_results
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
        statuses: process_statuses,
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

    def process_facts(result)
      # TODO: add fact processing and sending to the fact endpoint
      result["result"]["ansible_facts"] = {}
    end

    def process_keywords(result)
      if result["failed"]
        add_keywords("HasFailure", "AnsibleTaskFailed:#{result["task"]["action"]}")
      elsif result["result"]["changed"]
        add_keywords("HasChange")
      end
    end

    def process_level(result)
      if result["failed"]
        result["level"] = "err"
      elsif result["result"]["changed"]
        result["level"] = "notice"
      else
        result["level"] = "info"
      end
    end

    def process_statuses
      {
        "applied" => @body["status"]["applied"],
        "failed" => @body["status"]["failed"],
        "pending" => @body["status"]["pending"] || 0, # It's only present in check mode
        "other" => @body["status"]["skipped"],
      }
    rescue StandardError => e
      logger.error "Unable to process statuses", e
      { "applied" => 0, "failed" => 0, "pending" => 0, "other" => 0 }
    end
  end
end
