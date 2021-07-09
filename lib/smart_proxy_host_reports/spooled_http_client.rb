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

  def start
    @worker_running = true
    @worker = Thread.new do
      while @worker_running
        begin
          logger.info "Started host reports spooled http client"
          process
          Thread.stop
        rescue StandardError => e
          logger.error "Error during spool processing: #{e}", e
        end
      end
      logger.info "Stopped host reports spooled http client"
    end
  end

  def stop
    @worker_running = false
    wakeup
  end

  def process
    processed = 0
    client = ::Proxy::HttpRequest::ForemanRequest.new
    factory = client.request_factory
    # send all files via a single persistent HTTP connection
    logger.debug "Opening HTTP connection to Foreman"
    client.http.start do |http|
      Dir.glob(spool_path("todo", "*")) do |filename|
        basename = File.basename(filename)
        logger.debug "Sending #{basename}"
        begin
          post = factory.create_post("/api/v2/host_reports", File.read(filename))
          http.request(post)
          if Proxy::HostReports::Plugin.settings.keep_reports
            spool_move("todo", "done", basename)
          else
            FileUtils.rm_f spool_path("todo", basename)
          end
          processed += 1
        rescue StandardError => e
          logger.warn "Unable to send #{basename}, will try on next request: #{e}", e
          raise if ENV["RACK_ENV"] == "test"
        end
      end
    end
    logger.debug "Finished uploading #{processed} reports, closing connection"
  end

  def wakeup
    @worker.wakeup if @worker
  end

  def spool(filename, data)
    filename = filename.gsub(/[^0-9a-z]/i, "")
    file = spool_path("temp", filename)
    File.open(file, "w") { |f| f.write(data) }
    spool_move("temp", "todo", filename)
    wakeup
  end
end
