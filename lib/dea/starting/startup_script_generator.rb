require 'dea/utils/platform_compat'
require 'dea/utils/windows_command'

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

    def generate
      # Generate the environment variables that will be used
      system_env_hash = Hash[*@env.system_environment_variables.flatten]
      user_env_hash = Hash[*@env.user_environment_variables.flatten]
      env_hash = system_env_hash.merge(user_env_hash)

      # Create a windows command with all the arguments
      working_dir = "@ROOT@\\app"
      exe = "#{working_dir}\\#{@start_command}"

      # The exe command args is an array where the first item is the
      # exe that will be invoked and the rest are the arguments.
      exe_command_args = [exe, "-p #{env_hash['PORT']}"]
      win_command = WindowsCommand.new('exe', exe_command_args, env_hash, working_dir)

      # Convert to json
      command = [
        win_command.to_hash
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
