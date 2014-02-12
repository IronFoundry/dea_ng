WINDOWS = (RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/)

module FileUtils
  def cp_a(src, dest)
    if WINDOWS
      FileUtils.cp_r(src, dest, :preserve => true)
    else
      system "cp -a #{src} #{dest}"
    end
  end
end
