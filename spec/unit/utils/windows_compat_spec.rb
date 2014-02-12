require 'spec_helper'
require 'dea/utils/windows_compat'

describe FileUtils do

  describe "#cp_a", unix_only:true do
    it "Copies files using system command" do
      # recursively (-r) while not following symlinks (-P) and preserving dir structure (-p)
      # this is why we use system copy not FileUtil
      FileUtils.should_receive(:system).with("cp -a fakesrcdir fakedestdir/app")

      FileUtils.cp_a "fakesrcdir", "fakedestdir/app"
    end
  end

  describe "#cp_a on windows", windows_only:true do
    it "Copies files using FileUtils" do
      stub_const('WINDOWS', true)
      FileUtils.should_receive(:cp_r).with("fakesrcdir", "fakedestdir/app", { :preserve => true })

      FileUtils.cp_a "fakesrcdir", "fakedestdir/app"
    end
  end
end