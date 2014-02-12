require 'spec_helper'
require 'dea/utils/platform_compat'

describe FileUtils do

  describe "#cp_a" do
    it "Copies files using system command" do
      stub_const('PlatformCompat::WINDOWS', false)
      # recursively (-r) while not following symlinks (-P) and preserving dir structure (-p)
      # this is why we use system copy not FileUtil
      FileUtils.should_receive(:system).with("cp -a fakesrcdir fakedestdir/app")

      FileUtils.cp_a "fakesrcdir", "fakedestdir/app"
    end
  end

  describe "#cp_a on windows", windows_only:true do
    it "Copies files using FileUtils" do
      stub_const('PlatformCompat::WINDOWS', true)
      FileUtils.should_receive(:cp_r).with("fakesrcdir", "fakedestdir/app", { :preserve => true })

      FileUtils.cp_a "fakesrcdir", "fakedestdir/app"
    end
  end
end

describe PlatformCompat do

  describe "#signal_supported?" do
    it "supports sigusr1 on linux" do
      stub_const('PlatformCompat::WINDOWS', false)
      PlatformCompat::signal_supported?("SIGUSR1").should be_true
    end

    it "supports term on windows" do
      stub_const('PlatformCompat::WINDOWS', true)
      PlatformCompat::signal_supported?("SIGTERM").should be_true
    end
  end
end