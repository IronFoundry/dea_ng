# 
# Command messages sent to the Windows Warden
# An array of WindowsCommand are serialized and sent in the script property
# of the warden messages such as Run or Spawn
#
# cmd - The command to run 
#       Currently supported: exe, mkdir, iis, ps1, replace-tokens, tar, touch, unzip
# args - an array of arguments to the command
# environment - A hashtable with environment variables and their values that should be set 
#               when running the command.
#
class WindowsCommand
    attr_accessor :cmd, :args, :env

    def initialize(cmd, args = [], env = {})
        @cmd = cmd
        @args = args
        @env = env
    end

  def to_hash
    hash = {}
    instance_variables.each do |var|
        var_name = var.to_s.delete("@")
        hash[var_name.to_sym] = instance_variable_get(var)
    end

    return hash;
  end
end