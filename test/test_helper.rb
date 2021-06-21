require 'rack/test'
require 'test/unit'
require 'mocha/test_unit'
require 'json-diff'
require 'webmock/test_unit'
require 'smart_proxy_for_testing'
require 'smart_proxy_host_reports'
require 'smart_proxy_host_reports/host_reports'
require 'smart_proxy_host_reports/host_reports_api'
require 'smart_proxy_host_reports/processor'
require 'smart_proxy_host_reports/puppet_processor'
require 'smart_proxy_host_reports/spooled_http_client'

LOG = "/tmp/proxy-test.log"
FileUtils.rm_f(LOG) if File.exist?(LOG)
::Proxy::SETTINGS.log_file = LOG

ENV["RACK_ENV"] = "test"
ENV["TESTOPTS"] = "--verbose"