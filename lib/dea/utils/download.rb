class Download
  attr_reader :uri, :blk, :destination_dir, :sha1_expected
  attr_reader :logger

  class DownloadError < StandardError
    attr_reader :data

    def initialize(msg, data = {})
      @data = data

      super("Error downloading: %s (%s)" % [uri, msg])
    end

    def uri
      data[:droplet_uri] || "(unknown)"
    end
  end

  def initialize(uri, destination_dir, sha1_expected=nil, custom_logger=nil)
    @uri = uri
    @destination_dir = destination_dir
    @sha1_expected = sha1_expected
    @logger = custom_logger || self.class.logger
  end

  def download!(&blk)
    FileUtils.mkdir_p(destination_dir)

    file = Tempfile.new("droplet", destination_dir)
    file.binmode
    sha1 = Digest::SHA1.new

    http = EM::HttpRequest.new(uri, :connect_timeout => 15, :inactivity_timeout => 30).get

    stream_err = nil

    http.stream do |chunk|
      tries = 0
      begin
        file << chunk
      rescue Errno::EBADF => err
        # ironfoundry TODO - this happens with some frequency in windows
        # trapping here to prevent DEA from crashing
        stream_err = err
        if tries < 2
          logger.error("Errno::EBADF in stream to file - retrying (closed: #{file.closed?})")
          file = Tempfile.new("droplet", destination_dir)
          file.binmode
          tries += 1
          retry
        else
          logger.error("Errno::EBADF in stream to file - DONE RETRYING")
        end
      rescue => err
        stream_err = err
      end

      begin
        sha1 << chunk
      rescue Errno::EBADF => err
        # trapping here to prevent DEA from crashing
        stream_err = err
        logger.error("Errno::EBADF in stream to sha1!")
      rescue => err
        stream_err = err
      end
    end

    cleanup = lambda do |&inner|
      begin
        file.close
        inner.call(nil)
      rescue => err
        inner.call(err)
      ensure
        FileUtils.rm_f(file.path)
      end
    end

    context = { :droplet_uri => uri }

    http.errback do
      cleanup.call do |cleanup_err|
        context = { :cleanup_err => cleanup_err, :stream_err => stream_err }
        error = DownloadError.new("Response status: unknown. Error: #{http.error} Http: #{http.inspect}", context)
        logger.error(error.message, error.data)
        blk.call(error)
      end
    end

    http.callback do
      cleanup.call do
        http_status = http.response_header.status

        context[:droplet_http_status] = http_status

        if http_status == 200
          sha1_actual   = sha1.hexdigest
          if !sha1_expected || sha1_expected == sha1_actual
            logger.info("Download succeeded")
            blk.call(nil, file.path)
          else
            context[:droplet_sha1_expected] = sha1_expected
            context[:droplet_sha1_actual]   = sha1_actual

            error = DownloadError.new("SHA1 mismatch", context)
            logger.warn(error.message, error.data)
            blk.call(error)
          end
        else
          error = DownloadError.new("HTTP status: #{http_status}", context)
          logger.warn(error.message, error.data)
          blk.call(error)
        end
      end
    end
  end
end
