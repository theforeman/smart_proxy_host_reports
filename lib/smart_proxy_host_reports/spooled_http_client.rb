class SpooledHttpClient
  include Proxy::Log

  def spool_path(state = "temp", filename = nil)
    if filename
      File.join(@spool_dir, state, filename)
    else
      File.join(@spool_dir, state)
    end
  end

  def spool_move(from_state, to_state, filename)
    # TODO: implement fsync?
    FileUtils.mv(spool_path(from_state, filename), spool_path(to_state, filename))
  end

  def initialize(spool_dir = Proxy::HostReports::Plugin.settings.spool_dir)
    @spool_dir = spool_dir
    @worker = nil
    ["temp", "todo", "done"].each do |state|
      FileUtils.mkdir_p(spool_path(state))
    end
  end

  def start_processing
    @worker = Thread.new do
      while true do
        begin
          Thread.stop
          process
        rescue Exception => e
          logger.error "Error during spool processing: #{e}", e
        end
      end
    end
  end

  def process
    processed = 0
    client = ::Proxy::HttpRequest::ForemanRequest.new
    factory = client.request_factory
    # send all files via a single persistent HTTP connection
    client.http.start do |http|
      Dir.glob(spool_path("todo", "*")) do |filename|
        basename = File.basename(filename)
        begin
          post = factory.create_post("/api/v2/host_reports", File.read(filename))
          http.request(post)
          if Proxy::HostReports::Plugin.settings.keep_reports
            spool_move("todo", "done", basename)
          else
            FileUtils.rm_f spool_path("todo", basename)
          end
          processed += 1
        rescue Exception => e
          logger.warn "Unable to send #{basename}, will try on next request: #{e}", e
          raise if ENV["RACK_ENV"] == "test"
        end
      end
    end
    logger.debug "Finished uploading #{processed} reports"
  end

  def wakeup
    @worker.wakeup if @worker
  end

  def spool(filename, data)
    filename = filename.gsub(/[^0-9a-z_-]/i, '')
    file = spool_path("temp", filename)
    File.open(file, 'w') { |f| f.write(data) }
    spool_move("temp", "todo", filename)
    wakeup
  end
end