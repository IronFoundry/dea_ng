require "dea/utils/platform_compat"

module Dea
  class Env
    class Exporter < Struct.new(:variables)
      def export
      	PlatformCompat.to_env(variables)
      end
    end
  end
end