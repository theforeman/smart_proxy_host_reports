require "smart_proxy_reports/reports_api"

map "/reports" do
  run Proxy::Reports::Api
end

# TODO: Deprecated, remove in 2.0
map "/host_reports" do
  run Proxy::Reports::Api
end
