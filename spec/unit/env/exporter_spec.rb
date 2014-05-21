require "spec_helper"
require "dea/env/exporter"
require "dea/utils/platform_compat"

module Dea
  class Env
    describe Exporter do
      subject(:env_exporter) { Exporter.new(variables) }
      platform_specific(:platform)

      context "with a single value" do
        let(:variables) { [[:a, 1]] }

        context "on Linux" do
          let(:platform) { :Linux }

          it "exports the variables" do
            expect(env_exporter.export).to eql(%Q{export a="1";\n})
          end
        end

        context "on Windows" do
          let(:platform) { :Windows }

          it "exports the variables" do
            expect(env_exporter.export).to eql(%Q{$env:a="1"\n})
          end
        end
      end

      context "with multiple values" do
        let(:variables) { [["a", 1], ["b", 2]] }

        context "on Linux" do
          let(:platform) { :Linux }

          it "exports the variables" do
            expect(env_exporter.export).to eql(%Q{export a="1";\nexport b="2";\n})
          end
        end

        context "on Windows" do
          let(:platform) { :Windows }

          it "exports the variables" do
            expect(env_exporter.export).to eql(%Q{$env:a="1"\n$env:b="2"\n})
          end
        end
      end

      context "with value containing quotes" do
        let(:variables) { [["a", %Q{"1'}]] }

        context "on Linux" do
          let(:platform) { :Linux }

          it "exports the variables" do
            expect(env_exporter.export).to eql(%Q{export a="\\"1'";\n})
          end
        end

        context "on Windows" do
          let(:platform) { :Windows }

          it "exports the variables" do
            expect(env_exporter.export).to eql(%Q{$env:a="`"1'"\n})
          end
        end
      end

      context "with non-string values" do
        let(:variables) { [[:a, :b]] }

        context "on Linux" do
          let(:platform) { :Linux }

          it "exports the variables" do
            expect(env_exporter.export).to eql(%Q{export a="b";\n})
          end
        end

        context "on Windows" do
          let(:platform) { :Windows }

          it "exports the variables" do
            expect(env_exporter.export).to eql(%Q{$env:a="b"\n})
          end
        end
      end

      context "with spaces in values" do
        let(:variables) { [[:a, "one two"]] }

        context "on Linux" do
          let(:platform) { :Linux }

          it "exports the variables" do
            expect(env_exporter.export).to eql(%Q{export a="one two";\n})
          end
        end

        context "on Windows" do
          let(:platform) { :Windows }

          it "exports the variables" do
            expect(env_exporter.export).to eql(%Q{$env:a="one two"\n})
          end
        end
      end

      context "with = in values" do
        let(:variables) { [[:a, "one=two"]] }

        context "on Linux" do
          let(:platform) { :Linux }

          it "exports the variables" do
            expect(env_exporter.export).to eql(%Q{export a="one=two";\n})
          end
        end

        context "on Windows" do
          let(:platform) { :Windows }

          it "exports the variables" do
            expect(env_exporter.export).to eql(%Q{$env:a="one=two"\n})
          end
        end
      end

      # Windows: we avoid this on Windows, because PowerShell variables have a different
      # namespace than Environment variables.
      # If this becomes a problem, we can look into parsing "$x" into "$env:x"
      context "when they reference each other in other in order", :unix_only => true do
        let(:variables) { [["x", "bar"], ["foo", "$x"]] }

        context "when evaluated by bash" do
          let(:evaluated_env) { `#{env_exporter.export} env` }

          it "substitutes the reference" do
            expect(evaluated_env).to include("x=bar")
            expect(evaluated_env).to include("foo=bar")
          end
        end
      end
    end

  end
end
