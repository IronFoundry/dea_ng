#!/usr/bin/env ruby
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'rubygems'
require 'bundler/setup'

$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))

require "eventmachine"
require "yaml"

require "dea/bootstrap"

require 'win32/daemon'
include Win32

unless ARGV.size == 1
  abort "Usage: dea_winsvc.rb <config path>"
end

begin
  $config = YAML.load_file(ARGV[0])
rescue => e
  abort "ERROR: Failed loading config: #{e}"
end

Kernel.at_exit { 
  Kernel.exit!(true) # NB: nothing else will stop the service.
}

class Daemon

  def service_main

    begin

      @bootstrap = Dea::Bootstrap.new($config)

      EM.run {
        @bootstrap.setup
        @bootstrap.start
      }

    rescue => e
      exit!
    end

  end

  def service_stop
    stop
  end

  def service_shutdown
    stop
  end

  def stop
    @bootstrap.shutdown
  end

end

Daemon.mainloop
