require 'rspec/core/formatters/html_snippet_extractor'

module RSpec
  module Core
    module Formatters
      RSpec.describe HtmlSnippetExtractor do
        it "falls back on a default message when it doesn't understand a line" do
          expect(RSpec::Core::Formatters::HtmlSnippetExtractor.new.snippet_for("blech")).to eq(["# Couldn't get snippet for blech", 1])
        end

        it "falls back on a default message when it doesn't find the file" do
          expect(RSpec::Core::Formatters::HtmlSnippetExtractor.new.lines_around("blech", 8)).to eq("# Couldn't get snippet for blech")
        end

        it "falls back on a default message when it gets a security error" do
          message = nil
          with_safe_set_to_level_that_triggers_security_errors do
            message = RSpec::Core::Formatters::HtmlSnippetExtractor.new.lines_around("blech".taint, 8)
          end
          expect(message).to eq("# Couldn't get snippet for blech")
        end

        describe "snippet extraction" do
          let(:snippet) do
            HtmlSnippetExtractor.new.snippet(["#{__FILE__}:#{__LINE__}"])
          end

          before do
            # `send` is required for 1.8.7...
            @orig_converter = HtmlSnippetExtractor.send(:class_variable_get, :@@converter)
          end

          after do
            HtmlSnippetExtractor.send(:class_variable_set, :@@converter, @orig_converter)
          end

          it 'suggests you install coderay when it cannot be loaded' do
            HtmlSnippetExtractor.send(:class_variable_set, :@@converter, HtmlSnippetExtractor::NullConverter)

            expect(snippet).to include("Install the coderay gem")
          end

          it 'does not suggest installing coderay normally' do
            expect(snippet).to exclude("Install the coderay gem")
          end
        end
      end
    end
  end
end
