# frozen_string_literal: true

class AnsibleProcessor < Processor
    def initialize(data)
      super(data)
      measure :parse do
        @data = JSON.parse(data)
      end
      @result = {}
      @keywords_set = {}
    end
  
    def process
      # TODO: must push the results to foreman instead of calling 
      @data["plays"].each do |play|
        uuid = @data['xxx'] || SecureRandom.uuid
        logger.debug "Processing report #{uuid}"
        logger.debug(@data) if debug_payload?
      end
    end
  
    def to_foreman
      measure :process do
        # TODO
        @result['format'] = 'ansible'
        @result['id'] = "TODO"
        @result['host'] = @data['host']
        @result['proxy'] = Proxy::HostReports::Plugin.settings.reported_proxy_hostname
        @result['reported_at'] = @data['time']
        @result['logs'] = "TODO"
        @result['keywords'] = @keywords_set.keys.to_a
        @result['errors'] = errors if errors?
      end
      if debug_payload?
        logger.debug { JSON.pretty_generate(@result) }
      end
      @result
    end
  end