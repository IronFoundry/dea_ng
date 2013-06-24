module Buildpacks
  class WinBuildpack < Buildpack

    def create_startup_script
      path = File.join(script_dir, 'startup.ps1')
      File.open(path, 'w') do |f|
        f.puts(startup_script)
      end
    end

    def environment_statements_for(vars)
      # Passed vars should overwrite common vars
      common_env_vars = { "TMPDIR" => tmp_dir.gsub(destination_directory,"$PWD") }
      vars = common_env_vars.merge(vars)
      lines = []
      vars.each do |name, value|
        if value
          lines << "$env:#{name}=\"#{value}\""
        else
          lines << "Remove-Item env:\\#{name}"
        end
      end
      lines.sort.join("\n")
    end

    def generate_startup_script(env_vars = {})
      # idea: just pass config data and env as startup?
      after_env_before_script = block_given? ? yield : "\n"
      <<-SCRIPT.gsub(/^\s{8}/, "")
        [CmdletBinding()]
        param([uint16] $port)
        <%= environment_statements_for(env_vars) %>
        <%= after_env_before_script %>
        $droplet_base_dir = $PWD
        $stdout_path = "$droplet_base_dir\\logs\\stdout.log"
        $stderr_path = "$droplet_base_dir\\logs\\stderr.log"
        cd app
        $process = Start-Process -FilePath .\\iishost\\iishost.exe -NoNewWindow -PassThru -RedirectStandardOutput $stdout_path -RedirectStandardError $stderr_path -ArgumentList "-p $port"
        Set-Content -Path "$droplet_base_dir\\run.pid" -Encoding ASCII $process.id
        Wait-Process -InputObject $process
      SCRIPT
    end

    def startup_script
      # the contents of .profile.d are created via the buildpack
      generate_startup_script(environment_variables) do
        # TODO ironfoundry
        # if [ -d app/.profile.d ]; then
        #   for i in app/.profile.d/*.sh; do
        #     if [ -r $i ]; then
        #       . $i
        #     fi
        #   done
        # fi
        script_content = <<-PS1
Get-ChildItem env: | Out-File -FilePath .\\logs\\env.log -Encoding ASCII -Force
PS1
        script_content
      end
    end

    def environment_variables
      vars = release_info['config_vars'] || {}
      vars.each { |k, v| vars[k] = "${#{k}:-#{v}}" }
      vars["HOME"] = "$PWD/app"
      vars["PORT"] = "$VCAP_APP_PORT"
      vars["MEMORY_LIMIT"] = "#{application_memory}m"
      vars
    end

  end
end

