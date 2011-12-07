require 'spec_helper'

module RSpec::Core

  describe World do
    let(:configuration) { Configuration.new }
    let(:world) { World.new(configuration) }

    describe "#example_groups" do
      it "contains all registered example groups" do
        group = ExampleGroup.describe("group")
        world.register(group)
        world.example_groups.should include(group)
      end
    end

    describe "#preceding_declaration_line (again)" do
      let(:group) do
        ExampleGroup.describe("group") do

          example("example")

        end
      end

      let(:second_group) do
        ExampleGroup.describe("second_group") do

          example("second_example")

        end
      end

      let(:group_declaration_line) { group.metadata[:example_group][:line_number] }
      let(:example_declaration_line) { group_declaration_line + 2 }

      context "with one example" do
        before { world.register(group) }

        it "returns nil if no example or group precedes the line" do
          world.preceding_declaration_line(group_declaration_line - 1).should be_nil
        end

        it "returns the argument line number if a group starts on that line" do
          world.preceding_declaration_line(group_declaration_line).should eq(group_declaration_line)
        end

        it "returns the argument line number if an example starts on that line" do
          world.preceding_declaration_line(example_declaration_line).should eq(example_declaration_line)
        end

        it "returns line number of a group that immediately precedes the argument line" do
          world.preceding_declaration_line(group_declaration_line + 1).should eq(group_declaration_line)
        end

        it "returns line number of an example that immediately precedes the argument line" do
          world.preceding_declaration_line(example_declaration_line + 1).should eq(example_declaration_line)
        end
      end

      context "with two examples when second one is registered first" do
        let(:second_group_declaration_line) { second_group.metadata[:example_group][:line_number] }

        before do 
          world.register(second_group)
          world.register(group)
        end

        it 'returns line number of a group if it starts on that line' do
          world.preceding_declaration_line(second_group_declaration_line).should eq(second_group_declaration_line)
        end
      end
    end

    describe "#announce_filters" do
      let(:reporter) { double('reporter').as_null_object }
      before { world.stub(:reporter) { reporter } }

      context "with no examples" do
        before { world.stub(:example_count) { 0 } }

        context "with no filters" do
          it "announces" do
            reporter.should_receive(:message).
              with("No examples found.")
            world.announce_filters
          end
        end

        context "with an inclusion filter" do
          it "announces" do
            configuration.filter_run_including :foo => 'bar'
            reporter.should_receive(:message).
              with(/All examples were filtered out/)
            world.announce_filters
          end
        end

        context "with an inclusion filter and run_all_when_everything_filtered" do
          it "announces" do
            configuration.stub(:run_all_when_everything_filtered?) { true }
            configuration.filter_run_including :foo => 'bar'
            reporter.should_receive(:message).
              with(/All examples were filtered out/)
            world.announce_filters
          end
        end

        context "with an exclusion filter" do
          it "announces" do
            configuration.filter_run_excluding :foo => 'bar'
            reporter.should_receive(:message).
              with(/All examples were filtered out/)
            world.announce_filters
          end
        end
      end

      context "with examples" do
        before { world.stub(:example_count) { 1 } }

        context "with no filters" do
          it "does not announce" do
            reporter.should_not_receive(:message)
            world.announce_filters
          end
        end
      end
    end
  end
end
