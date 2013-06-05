require "json"
require "tempfile"
require "tmpdir"
require "yaml"

require "dea/utils/download"
require "dea/utils/upload"
require "dea/promise"
require "dea/task"
require "dea/staging_task"
require "dea/staging_task_workspace"

module Dea
  class WinStagingTask < StagingTask
    def promise_app_dir
      Promise.new do |p|
        # Some buildpacks seem to make assumption that /app is a non-empty directory
        # See: https://github.com/heroku/heroku-buildpack-python/blob/master/bin/compile#L46
        commands = [
          { :cmd => 'mkdir', :args => [ 'CROOT/app' ] },
          { :cmd => 'touch', :args => [ 'CROOT/app/support_heroku_buildpacks' ] },
          # NB: chown not necessary as /app will inherit perms
        ]

        promise_warden_run(:app, commands.to_json, true).resolve
        p.deliver
      end
    end
  end
end

