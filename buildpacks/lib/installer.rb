require "open3"

module Buildpacks

  WINDOWS = RbConfig::CONFIG['host_os'] =~ /mswin|mingw/

  class Installer < Struct.new(:path, :app_dir, :cache_dir)
    def detect
      @detect_output, status = Open3.capture2 command('detect')
      status == 0
    end

    def name
      @detect_output ? @detect_output.strip : nil
    end

    def compile
      puts "Installing #{path.basename}."
      ok = system "#{command('compile')} #{cache_dir}"
      raise "Buildpack compilation step failed:\n" unless ok
    end

    def release_info
      output, status = Open3.capture2 command("release")
      raise "Release info failed:\n#{output}" unless status == 0
      YAML.load(output)
    end

    private

    def command(command_name)
      cmd = File.join(path, 'bin', command_name)
      # TODO ironfoundry
      # if WINDOWS
      #   case cmd
      #     when File.exists?("#{cmd}.ps1")
      #       cmd = "powershell.exe -ExecutionPolicy RemoteSigned -NoLogo -NoProfile -NonInteractive #{cmd}.ps1" # TODO ironfoundry
      #     when File.exists?("#{cmd}.rb")
      #       cmd = "ruby.exe #{cmd}.rb" # TODO ironfoundry
      #   end
      # end
      if WINDOWS
        cmd = "ruby.exe #{cmd}" # TODO ironfoundry this requires ruby.exe in the PATH, assumes command_name is a ruby script
      end
      "#{cmd} #{app_dir}"
    end
  end
end

