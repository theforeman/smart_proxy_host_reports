require 'sinatra'
require 'yaml'
require 'smart_proxy_host_reports/host_reports'
require 'smart_proxy_host_reports/processor'
require 'smart_proxy_host_reports/puppet_processor'

module Proxy::HostReports
  class Api < ::Sinatra::Base
    include ::Proxy::Log
    helpers ::Proxy::Helpers

    before do
      content_type 'application/json'
      halt(415, "Content type must be application/x-yaml") if request.env["CONTENT_TYPE"] != "application/x-yaml"
    end
    
    post '/:format' do
      format = params[:format]
      halt(404, "Format argument not specified") unless format
      input = request.body.read
      halt(415, "Missing body") if input.empty?
      processor = Processor.new_processor(format, input)
      processor.to_foreman.to_json
    rescue => e
      log_halt 415, "Error during report processing: \n#{e.message}"
    end
  end
end
