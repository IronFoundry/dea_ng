require "json"

module Dea
  class WinStagingTask < StagingTask

    def promise_prepare_staging_log_script(warden_staged_dir, warden_staging_log)
      commands = [
        { :cmd => 'mkdir', :args => [ "@ROOT@/#{warden_staged_dir}/logs" ] },
        { :cmd => 'touch', :args => [ "@ROOT@/#{warden_staging_log}" ] },
      ]
      commands.to_json
    end

    def promise_app_dir_script
      # NB: chown not necessary as /app will inherit perms
      commands = [
        { :cmd => 'mkdir', :args => [ '@ROOT@/app' ] },
        { :cmd => 'touch', :args => [ '@ROOT@/app/support_heroku_buildpacks' ] },
      ]
      commands.to_json
    end

    def promise_unpack_app_script(droplet_path, warden_staging_log, warden_unstaged_dir)
      commands = [
        { :cmd => 'ps1', :args => [ %Q|Add-Content -Encoding ASCII -Path @ROOT@/#{warden_staging_log} "----> Downloaded app package ($('{0:N0}' -f ($(Get-Item '#{droplet_path}').Length / 1KB))KB)"| ] },
        { :cmd => 'unzip', :args => [ droplet_path, "@ROOT@/#{wanden_unstaged_dir}" ] },
      ]
      commands.to_json
    end

  end
end

