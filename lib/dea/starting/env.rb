# coding: UTF-8
require 'dea/utils/platform_compat'

module Dea
  module Starting
    class Env
      attr_reader :message, :instance

      def initialize(message, instance)
        @message = message
        @instance = instance
      end

      def system_environment_variables
        container_root = PlatformCompat.windows? ? "@ROOT@" : "$PWD"

        sys_env = [
          ["HOME", "#{container_root}/app"],
          ["TMPDIR", "#{container_root}/tmp"],
          ["VCAP_APP_HOST", "0.0.0.0"],
          ["VCAP_APP_PORT", @instance.instance_container_port],
          ["PORT", instance.instance_container_port]
        ]

        if PlatformCompat.windows?
          sys_env += [
            ["TEMP", "#{container_root}/tmp"],
            ["TMP",  "#{container_root}/tmp"]
          ]
        end

        sys_env
      end

      def vcap_application
        start_time = Time.at(@instance.state_starting_timestamp)
        {
          "application_id" => @instance.attributes["application_id"],
          "instance_id" => @instance.attributes["instance_id"],
          "instance_index" => @message.index,
          "host" => "0.0.0.0",
          "port" => @instance.instance_container_port,
          "started_at" => start_time,
          "started_at_timestamp" => start_time.to_i,
          "start" => start_time,
          "state_timestamp" => start_time.to_i,
        }
      end
    end
  end
end
