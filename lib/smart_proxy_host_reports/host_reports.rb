module Proxy::Reports
  class PluginConfiguration
    def load_classes
      require "smart_proxy_reports/spooled_http_client"
    end

    def load_dependency_injection_wirings(container, _settings)
      container.singleton_dependency :reports_spool, -> {
          SpooledHttpClient.instance.initialize_directory
        }
    end
  end

  class Plugin < ::Proxy::Plugin
    plugin :reports, Proxy::Reports::VERSION

    default_settings reported_proxy_hostname: "localhost",
      debug_payload: false,
      spool_dir: "/var/lib/foreman-proxy/reports",
      keep_reports: false

    http_rackup_path File.expand_path("reports_http_config.ru", File.expand_path("../", __FILE__))
    https_rackup_path File.expand_path("reports_http_config.ru", File.expand_path("../", __FILE__))

    load_classes PluginConfiguration
    load_dependency_injection_wirings PluginConfiguration
    start_services :reports_spool
  end
end
