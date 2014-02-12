require 'rbconfig'

module PlatformCompat
  WINDOWS = (RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/)
  def self.windows?
    WINDOWS
  end

  def self.platform_name
    if windows?
      "Windows"
    else
      "Linux"
    end
  end
end

class Class
  def abstract_method(*methods)
    methods.each do |m|
      define_method(m) do |*args|
        raise "Abstract method not implemented"
      end
    end
  end

  def include_platform_compat
    klass = self
    idx = klass.name.rindex("::")
    idx = idx ? idx + 2 : 0
    platformKlassName = klass.name.insert(idx, PlatformCompat::platform_name)

    klass.class_eval %Q{
     def self.new(*args)
       platformKlass = #{platformKlassName}
       object = platformKlass.allocate
       object.send :initialize, *args
       object
     end
   }
  end
end

module FileUtils
  def self.cp_a(src, dest)
    if PlatformCompat.windows?
      FileUtils.cp_r(src, dest, :preserve => true)
    else
      # recursively (-r) while not following symlinks (-P) and preserving dir structure (-p)
      # this is why we use system copy not FileUtil
      system "cp -a #{src} #{dest}"
    end
  end
end
