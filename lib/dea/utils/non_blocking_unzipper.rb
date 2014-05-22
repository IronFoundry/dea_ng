require 'dea/utils/platform_compat'

class NonBlockingUnzipper
  include_platform_compat
  abstract_method :unzip_to_folder
end

class LinuxNonBlockingUnzipper < NonBlockingUnzipper
  def unzip_to_folder(file, dest_dir, mode=0755)
    tmp_dir = Dir.mktmpdir
    File.chmod(mode, tmp_dir)
    EM.system "unzip -q #{file} -d #{tmp_dir}" do
      FileUtils.mv(tmp_dir, dest_dir)
      yield
    end
  end
end

class WindowsNonBlockingUnzipper < NonBlockingUnzipper
  def unzip_to_folder(file, dest_dir, mode=0755)
    # While we are using the same 'unzip' utility on Windows, we can't use
    # EM.system() to run it asynchronously because Windows doesn't support
    # the socketpair() call (and attempting to call socketpair() crashes
    # the application).
    ok = system("unzip -q #{file} -d #{dest_dir}")
    unless ok 
      raise "Error unzipping #{file}: #{$?}"
    end

    yield
  end
end
