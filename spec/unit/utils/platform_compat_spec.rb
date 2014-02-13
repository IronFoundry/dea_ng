require 'spec_helper'
require 'dea/utils/platform_compat'

describe FileUtils do

  describe "#cp_a" do
    it "Copies files using system command" do

      # recursively (-r) while not following symlinks (-P) and preserving dir structure (-p)
      # this is why we use system copy not FileUtil
      PlatformCompat.as_platform :Linux do
        FileUtils.should_receive(:system).with("cp -a fakesrcdir fakedestdir/app")
        FileUtils.cp_a "fakesrcdir", "fakedestdir/app"
      end
    end

    it "Copies files using FileUtils" do
      PlatformCompat.as_platform :Windows do
        FileUtils.should_receive(:cp_r).with("fakesrcdir", "fakedestdir/app", { :preserve => true })

        FileUtils.cp_a "fakesrcdir", "fakedestdir/app"
      end
    end
  end
end

describe PlatformCompat do

  describe "#signal_supported?" do
    it "supports sigusr1 on linux" do
      PlatformCompat.as_platform :Linux do
        PlatformCompat.signal_supported?("SIGUSR1").should be_true
      end
    end

    it "supports term on windows" do
      PlatformCompat.as_platform :Windows do
        PlatformCompat.signal_supported?("SIGTERM").should be_true
      end
    end
  end

  describe "#to_env" do
    it "exports on linux" do
      PlatformCompat.as_platform :Linux do
        expect(PlatformCompat.to_env({"foo" => "bar"})).to eq %Q{export foo="bar";\n}
      end
    end

    it "exports on linux with quotes" do
      PlatformCompat.as_platform :Linux do
        expect(PlatformCompat.to_env({"foo" => %Q{bar"foo"}})).to eq "export foo=\"bar\\\"foo\\\"\";\n"
      end
    end

    it "env on windows" do
      PlatformCompat.as_platform :Windows do
        expect(PlatformCompat.to_env({"foo" => "bar"})).to eq %Q{$env:foo='bar'\n}
      end
    end
  end
end