require "spec_helper"
require "dea/starting/startup_script_generator"
require "dea/utils/platform_compat"

describe Dea::StartupScriptGenerator do
  platform_specific(:platform, default_platform: :Linux)

  let(:used_buildpack) { '' }
  let(:start_command) { "go_nuts 'man' ; echo 'wooooohooo'" }

  let(:env_inst) { double(Dea::Env, :exported_user_environment_variables => user_envs, :exported_system_environment_variables => system_envs) }
  let(:generator) { Dea::StartupScriptGenerator.new(start_command, env_inst) }

  describe "#generate" do
    subject(:script) { generator.generate }

    context "on Linux" do
      let(:platform) { :Linux }
      let(:user_envs) { %Q{export usr1="usrval1";\nexport usr2="usrval2";\nunset unset_var;\n} }
      let(:system_envs) { %Q{export usr1="sys_user_val1";\nexport sys1="sysval1";\n} }

      describe "umask" do
        it "sets the umask to 077" do
          script.should include "umask 077"
        end
      end

      describe "environment variables" do
        it "exports the user env variables" do
          script.should include user_envs
        end

        it "exports the system env variables" do
          script.should include system_envs
        end

        it "sources the buildpack env variables" do
          script.should include "in app/.profile.d/*.sh"
          script.should include ". $i"
        end

        it "exports user variables after system variables" do
          script.should match /usr1="sys_user_val1".*usr1="usrval1"/m
        end

        it "exports build pack variables after system variables" do
          script.should match /"sysval1".*\.profile\.d/m
        end

        it "sets user variables after buildpack variables" do
          script.should match /\.profile\.d.*usrval1/m
        end
      end

      describe "starting app" do
        it "includes the escaped start command in the starting script" do
          expect(script).to include(Dea::LinuxStartupScriptGenerator::START_SCRIPT % Shellwords.shellescape(start_command))
        end
      end
    end

    context "on Windows" do
      let(:platform) { :Windows }
      let(:env_inst) { double(Dea::Env, :user_environment_variables => user_envs, :system_environment_variables => system_envs) }
      let(:user_envs) { [['usr1', 'usrval1'], ['usr2', 'usrval2']] }
      let(:system_envs) { [['usr1', 'sys_user_val1'], ['sys1', 'sysval1']] }

      describe "starting app" do
        it "includes the start command in the starting script" do
          script.should include start_command
        end
      end

      describe "environment variables" do 
        it "overrides system variables with user variables" do
          script.should include "\"usr1\":\"usrval1\""
        end
      end

    end
  end
end
