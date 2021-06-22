module Proxy::HostReports
  class Plugin < ::Proxy::Plugin
    plugin :host_reports, Proxy::HostReports::VERSION

    default_settings reported_proxy_hostname: "localhost",
      debug_payload: false,
      spool_dir: "/var/lib/foreman-proxy",
      keep_reports: false

    http_rackup_path File.expand_path("host_reports_http_config.ru", File.expand_path("../", __FILE__))
    https_rackup_path File.expand_path("host_reports_http_config.ru", File.expand_path("../", __FILE__))
  end
end
