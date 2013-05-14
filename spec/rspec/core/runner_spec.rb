require 'spec_helper'
require 'rspec/core/drb_command_line'

module RSpec::Core
  describe Runner do
    describe 'at_exit' do
      let(:runner) { RSpec::Core::Runner.new }
      before { runner.stub(:running_in_drb?).and_return(false) }

      it 'sets an at_exit hook if none is already set' do
        runner.stub(:installed_at_exit?).and_return(false)
        runner.should_receive(:at_exit)
        runner.autorun
      end

      it 'does not set the at_exit hook if it is already set' do
        runner.stub(:installed_at_exit?).and_return(true)
        runner.should_not_receive(:at_exit)
        runner.autorun
      end
    end

    describe "configuration and setup" do
      let(:runner) { RSpec::Core::Runner.new }
      before { RSpec::Core::CommandLine.stub(:new).and_return(double(:run => 1)) }

      it "sets up the dsl once" do
        Module.should_receive(:include).with(RSpec::Core::DSL).once
        RSpec::Core::Runner.main_object.should_receive(:extend).with(RSpec::Core::DSL).once
        2.times { runner.run }
      end

      it "doesn't set up the dsl if we don't want it to" do
        Module.should_not_receive(:include)
        RSpec::Core::Runner.main_object.should_not_receive(:extend)
        runner.run(["--no-toplevel-dsl"])
      end

      it "doesn't overwrite existing options with empty options" do
        ConfigurationOptions.should_receive(:new).once.and_call_original
        runner.run(["--fail-fast"])
        runner.run([])
      end
    end

    describe "#run" do
      let(:err) { StringIO.new }
      let(:out) { StringIO.new }

      it "tells RSpec to reset" do
        RSpec.configuration.stub(:files_to_run => [])
        RSpec.should_receive(:reset)
        RSpec::Core::Runner.run([], err, out)
      end

      context "with --drb or -X" do

        before(:each) do
          @options = RSpec::Core::ConfigurationOptions.new(%w[--drb --drb-port 8181 --color])
          RSpec::Core::ConfigurationOptions.stub(:new) { @options }
        end

        def run_specs
          RSpec::Core::Runner.run(%w[ --drb ], err, out)
        end

        context 'and a DRb server is running' do
          it "builds a DRbCommandLine and runs the specs" do
            drb_proxy = double(RSpec::Core::DRbCommandLine, :run => true)
            drb_proxy.should_receive(:run).with(err, out)

            RSpec::Core::DRbCommandLine.should_receive(:new).and_return(drb_proxy)

            run_specs
          end
        end

        context 'and a DRb server is not running' do
          before(:each) do
            RSpec::Core::DRbCommandLine.should_receive(:new).and_raise(DRb::DRbConnError)
          end

          it "outputs a message" do
            RSpec.configuration.stub(:files_to_run) { [] }
            err.should_receive(:puts).with(
              "No DRb server is running. Running in local process instead ..."
            )
            run_specs
          end

          it "builds a CommandLine and runs the specs" do
            process_proxy = double(RSpec::Core::CommandLine, :run => 0)
            process_proxy.should_receive(:run).with(err, out)

            RSpec::Core::CommandLine.should_receive(:new).and_return(process_proxy)

            run_specs
          end
        end
      end
    end
  end
end
