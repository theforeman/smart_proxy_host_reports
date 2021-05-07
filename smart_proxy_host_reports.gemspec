# frozen_string_literal: true
require_relative 'lib/smart_proxy_host_reports/version'

Gem::Specification.new do |s|
  s.name = 'smart_proxy_host_reports'
  s.version = Proxy::HostReports::VERSION

  s.summary = 'Foreman Host Reports processor'
  s.description = 'Transform and upload Foreman host reports via REST API'
  s.authors = ['Lukas Zapletal']
  s.email = 'lukas-x@zapletalovi.com'
  s.extra_rdoc_files = ['README.md', 'LICENSE']
  s.files = Dir['{lib,settings.d,bundler.d}/**/*'] + s.extra_rdoc_files
  s.homepage = 'http://github.com/theforeman/smart_proxy_host_reports'
  s.license = 'GPL-3.0-or-later'

  s.add_dependency "concurrent-ruby", "~> 1.0"
  s.add_dependency "json", ">= 2.3.0"
  s.add_dependency "rack", ">= 2.1.0"
end
