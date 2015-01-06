require 'spec_helper'
require 'dea/utils/windows_command'

describe WindowsCommand do
  let(:cmd) { 'ps1' }
  let (:args) { ['arg1', 'arg2'] }
  let (:env) { { :env1 => 'value', :env2 => 'value'} }


  subject(:windows_command) { WindowsCommand.new(cmd, args, env) }

  context "on to_hash" do

    it "converts the WindowsCommand to a hash" do
      expect(windows_command.to_hash).to include(
        :cmd => cmd,
        :args => args,
        :env => env
        )
    end

  end
end
