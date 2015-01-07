require 'dea/utils/platform_compat'

module Dea
  class StartupScriptGenerator
    
    include_platform_compat
    abstract_method :generate

    def self.strip_heredoc(string)
      indent = string.scan(/^[ \t]*(?=\S)/).min.try(:size) || 0
      string.gsub(/^[ \t]{#{indent}}/, '')
    end
    
    def initialize(start_command, script_env)
      @start_command = start_command
      @env = script_env
    end
  end
  
  class WindowsStartupScriptGenerator < StartupScriptGenerator
    WIN_START_SCRIPT = strip_heredoc(<<-BASH).freeze
        $droplet_base_dir = $PWD
        $env:path += ";$(Resolve-Path ./app)"
        dir env: | %%{"{0}={1}" -f $_.Name, $_.Value} | Out-File -Encoding UTF8 -Force -FilePath "$droplet_base_dir\\logs\\env.log"
        cd app
        $process = Start-Process -FilePath %s -NoNewWindow -PassThru -ArgumentList "-p $env:PORT"
        Set-Content -Path "$droplet_base_dir\\run.pid" -Encoding ASCII $process.id
        Wait-Process -InputObject $process
    BASH

    def generate
      user_envs = @env.exported_user_environment_variables
      system_envs = @env.exported_system_environment_variables

      script = []
      script << @system_envs
      script << @user_envs
      script << WIN_START_SCRIPT % @start_command
      script.join("\n")

      command = [
          { :cmd => 'ps1', :args => script }
      ]
      command.to_json
    end
  end
  
  class LinuxStartupScriptGenerator < StartupScriptGenerator
    EXPORT_BUILDPACK_ENV_VARIABLES_SCRIPT = strip_heredoc(<<-BASH).freeze
      unset GEM_PATH
      if [ -d app/.profile.d ]; then
        for i in app/.profile.d/*.sh; do
          if [ -r $i ]; then
            . $i
          fi
        done
        unset i
      fi
    BASH

    START_SCRIPT = strip_heredoc(<<-BASH).freeze
      DROPLET_BASE_DIR=$PWD
      cd app
      echo $$ >> $DROPLET_BASE_DIR/run.pid
      exec bash -c %s
    BASH

    def generate
      user_envs = @env.exported_user_environment_variables
      system_envs = @env.exported_system_environment_variables

      script = []
      script << "umask 077"
      script << system_envs
      script << EXPORT_BUILDPACK_ENV_VARIABLES_SCRIPT
      script << user_envs
      script << START_SCRIPT % Shellwords.shellescape(@start_command)
      script.join("\n")
    end
  end
end
