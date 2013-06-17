# coding: UTF-8

module Dea
  class WinInstance < Instance

    def promise_setup_environment_script
      # cd / && mkdir -p home/vcap/app && chown vcap:vcap home/vcap/app && ln -s home/vcap/app /app
      commands = [
        { :cmd => 'mkdir', :args => [ '@ROOT@/home/vcap/app' ] },
        { :cmd => 'mkdir', :args => [ '@ROOT@/app' ] },
      ]
      commands.to_json
    end

    def promise_extract_droplet_script(droplet_path)
      # tar -C /home/vcap -xzf #{droplet.droplet_path}
      commands = [
        { :cmd => 'tar', :args => [ 'x', '@ROOT@/home/vcap', droplet_path ] },
      ]
      commands.to_json
    end

    def build_env(script)
      env = Env.new(self)
      env.env.each do |k, v|
        script << "$env:%s='%s'" % [k, v]
      end
    end

    def promise_start_script
      script = []

      build_env(script)

      startup = %q|.\startup.ps1|

      # Pass port to startup.ps1 if we have one
      if self.instance_host_port
        startup << ' -port %d' % self.instance_host_port
      end

      script << startup
      script << "exit"

      commands = [ { :cmd => 'ps1', :args => script } ]
      commands.to_json
    end

    def build_promise_exec_hook_script(script_path)
      script = []

      build_env(script)

      script << File.read(script_path)
      script << "exit"

      commands = [ { :cmd => 'ps1', :args => script } ]
      commands.to_json
    end

    def container_relative_path(root, *parts)
      # warden_path = attributes["warden_container_path"]
      # container_relative_path = File.join(warden_path, *parts)
      container_relative_path = super(root, *parts)
      log(:debug2, "container_relative_path('#{root}', '#{parts.inspect}'), rv '#{rv}'")
      return container_relative_path;
    end

    def promise_copy_out_src_dir
      "@ROOT@/home/vcap"
    end

  end
end

