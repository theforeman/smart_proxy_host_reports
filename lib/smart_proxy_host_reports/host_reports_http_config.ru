require "smart_proxy_host_reports/host_reports_api"

map "/host_reports" do
  run Proxy::HostReports::Api
end
