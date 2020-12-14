require 'open3'
RSpec::Support.require_rspec_core "bisect/server"

module RSpec
  module Core
    module Bisect
      # Provides an API to run the suite for a set of locations, using
      # the given bisect server to capture the results.
      #
      # Sets of specs are run by shelling out.
      # @private
      class ShellRunner
        def self.start(shell_command, _spec_runner)
          Server.run do |server|
            yield new(server, shell_command)
          end
        end

        def self.name
          :shell
        end

        def initialize(server, shell_command)
          @server        = server
          @shell_command = shell_command
        end

        def run(locations)
          run_locations(locations, original_results.failed_example_ids)
        end

        def original_results
          @original_results ||= run_locations(@shell_command.original_locations)
        end

      private

        def run_locations(*capture_args)
          @server.capture_run_results(*capture_args) do
            run_command @shell_command.command_for([], @server)
          end
        end

        def run_command(cmd)
          Open3.capture2e(@shell_command.bisect_environment_hash, cmd).first
        end
      end
    end
  end
end
