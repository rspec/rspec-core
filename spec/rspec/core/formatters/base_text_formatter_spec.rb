require 'spec_helper'
require 'rspec/core/formatters/base_text_formatter'

RSpec.describe RSpec::Core::Formatters::BaseTextFormatter do
  include FormatterSupport

  describe "#dump_summary" do
    it "with 0s outputs pluralized (excluding pending)" do
      send_notification :dump_summary, summary_notification(0, [], [], [], 0)
      expect(output.string).to match("0 examples, 0 failures")
    end

    it "with 1s outputs singular (including pending)" do
      send_notification :dump_summary, summary_notification(0, examples(1), examples(1), examples(1), 0)
      expect(output.string).to match("1 example, 1 failure, 1 pending")
    end

    it "with 2s outputs pluralized (including pending)" do
      send_notification :dump_summary, summary_notification(2, examples(2), examples(2), examples(2), 0)
      expect(output.string).to match("2 examples, 2 failures, 2 pending")
    end
  end

  describe "#dump_commands_to_rerun_failed_examples" do
    it "includes command to re-run each failed example" do
      group = RSpec::Core::ExampleGroup.describe("example group") do
        it("fails") { fail }
      end
      line = __LINE__ - 2
      group.run(reporter)
      formatter.dump_commands_to_rerun_failed_examples
      expect(output.string).to include("rspec #{RSpec::Core::Metadata::relative_path("#{__FILE__}:#{line}")} # example group fails")
    end
  end

  describe "#dump_failures" do
    let(:group) { RSpec::Core::ExampleGroup.describe("group name") }

    before { allow(RSpec.configuration).to receive(:color_enabled?) { false } }

    def run_all_and_dump_failures
      group.run(reporter)
      send_notification :dump_failures, null_notification
    end

    it "preserves formatting" do
      group.example("example name") { expect("this").to eq("that") }

      run_all_and_dump_failures

      expect(output.string).to match(/group name example name/m)
      expect(output.string).to match(/(\s+)expected: \"that\"\n\1     got: \"this\"/m)
    end

    context "with an exception without a message" do
      it "does not throw NoMethodError" do
        exception_without_message = Exception.new()
        allow(exception_without_message).to receive(:message) { nil }
        group.example("example name") { raise exception_without_message }
        expect { run_all_and_dump_failures }.not_to raise_error
      end

      it "preserves ancestry" do
        example = group.example("example name") { raise "something" }
        run_all_and_dump_failures
        expect(example.example_group.parent_groups.size).to eq 1
      end
    end

    context "with an exception that has an exception instance as its message" do
      it "does not raise NoMethodError" do
        gonzo_exception = RuntimeError.new
        allow(gonzo_exception).to receive(:message) { gonzo_exception }
        group.example("example name") { raise gonzo_exception }
        expect { run_all_and_dump_failures }.not_to raise_error
      end
    end

    context "with an instance of an anonymous exception class" do
      it "substitutes '(anonymous error class)' for the missing class name" do
        exception = Class.new(StandardError).new
        group.example("example name") { raise exception }
        run_all_and_dump_failures
        expect(output.string).to include('(anonymous error class)')
      end
    end

    context "with an exception class other than RSpec" do
      it "does not show the error class" do
        group.example("example name") { raise NameError.new('foo') }
        run_all_and_dump_failures
        expect(output.string).to match(/NameError/m)
      end
    end

    context "with a failed expectation (rspec-expectations)" do
      it "does not show the error class" do
        group.example("example name") { expect("this").to eq("that") }
        run_all_and_dump_failures
        expect(output.string).not_to match(/RSpec/m)
      end
    end

    context "with a failed message expectation (rspec-mocks)" do
      it "does not show the error class" do
        group.example("example name") { expect("this").to receive("that") }
        run_all_and_dump_failures
        expect(output.string).not_to match(/RSpec/m)
      end
    end

    context 'for #shared_examples' do
      it 'outputs the name and location' do
        group.shared_examples 'foo bar' do
          it("example name") { expect("this").to eq("that") }
        end

        line = __LINE__.next
        group.it_should_behave_like('foo bar')

        run_all_and_dump_failures

        expect(output.string).to include(
          'Shared Example Group: "foo bar" called from ' +
            "#{RSpec::Core::Metadata.relative_path(__FILE__)}:#{line}"
        )
      end

      context 'that contains nested example groups' do
        it 'outputs the name and location' do
          group.shared_examples 'foo bar' do
            describe 'nested group' do
              it("example name") { expect("this").to eq("that") }
            end
          end

          line = __LINE__.next
          group.it_should_behave_like('foo bar')

          run_all_and_dump_failures

          expect(output.string).to include(
            'Shared Example Group: "foo bar" called from ' +
              "./spec/rspec/core/formatters/base_text_formatter_spec.rb:#{line}"
          )
        end
      end
    end
  end

  describe "#dump_profile_slowest_examples", :slow do
    example_line_number = nil

    before do
      group = RSpec::Core::ExampleGroup.describe("group") do
        example("example") do |example|
          # make it look slow without actually taking up precious time
          example.clock = class_double(RSpec::Core::Time, :now => RSpec::Core::Time.now + 0.5)
        end
        example_line_number = __LINE__ - 4
      end
      group.run(reporter)

      allow(formatter).to receive(:examples) { group.examples }
      allow(RSpec.configuration).to receive(:profile_examples) { 10 }
    end

    it "names the example" do
      formatter.dump_profile_slowest_examples
      expect(output.string).to match(/group example/m)
    end

    it "prints the time" do
      formatter.dump_profile_slowest_examples
      expect(output.string).to match(/0(\.\d+)? seconds/)
    end

    it "prints the path" do
      formatter.dump_profile_slowest_examples
      filename = __FILE__.split(File::SEPARATOR).last

      expect(output.string).to match(/#{filename}\:#{example_line_number}/)
    end

    it "prints the percentage taken from the total runtime" do
      formatter.dump_profile_slowest_examples
      expect(output.string).to match(/, 100.0% of total time\):/)
    end
  end

  describe "#dump_profile_slowest_example_groups", :slow do
    let(:group) do
      RSpec::Core::ExampleGroup.describe("slow group") do
        example("example") do |example|
          # make it look slow without actually taking up precious time
          example.clock = class_double(RSpec::Core::Time, :now => RSpec::Core::Time.now + 0.5)
        end
      end
    end

    before do
      group.run(reporter)
      allow(RSpec.configuration).to receive(:profile_examples) { 10 }
    end

    context "with one example group" do
      before { allow(formatter).to receive(:examples) { group.examples } }

      it "doesn't profile a single example group" do
        formatter.dump_profile_slowest_example_groups
        expect(output.string).not_to match(/slowest example groups/)
      end
    end

    context "with multiple example groups" do
      before do
        group2 = RSpec::Core::ExampleGroup.describe("fast group") do
          example("example 1") { }
          example("example 2") { }
        end
        group2.run(reporter)

        allow(formatter).to receive(:examples) { group.examples + group2.examples }
      end

      it "prints the slowest example groups" do
        formatter.dump_profile_slowest_example_groups
        expect(output.string).to match(/slowest example groups/)
      end

      it "prints the time" do
        formatter.dump_profile_slowest_example_groups
        expect(output.string).to match(/0(\.\d+)? seconds/)
      end

      it "ranks the example groups by average time" do
        formatter.dump_profile_slowest_example_groups
        expect(output.string).to match(/slow group(.*)fast group/m)
      end
    end

    it "depends on parent_groups to get the top level example group" do
      ex = ""
      group.describe("group 2") do
        describe "group 3" do
          ex = example("nested example 1")
        end
      end

      expect(ex.example_group.parent_groups.last).to eq(group)
    end
  end

  describe "custom_colors" do
    it "uses the custom success color" do
      RSpec.configure do |config|
        config.color = true
        config.tty = true
        config.success_color = :cyan
      end
      send_notification :dump_summary, summary_notification(0, examples(1), [], [], 0)
      expect(output.string).to include("\e[36m")
    end
  end

end
