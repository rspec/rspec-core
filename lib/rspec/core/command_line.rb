module RSpec
  module Core
    class CommandLine
      def initialize(options, configuration=RSpec::configuration, world=RSpec::world)
        if Array === options
          options = ConfigurationOptions.new(options)
          options.parse_options
        end
        @options       = options
        @configuration = configuration
        @world         = world
      end

      # Configures and runs a suite
      #
      # @param [IO] err
      # @param [IO] out
      def run(err, out)
        @configuration.error_stream = err
        @configuration.output_stream ||= out
        @options.configure(@configuration)
        @configuration.load_spec_files
        @world.announce_filters

        @configuration.reporter.report(@world.example_count, @configuration.randomize? ? @configuration.seed : nil) do |reporter|
          begin
            @configuration.run_hook(:before, :suite)
            example_groups_ran = 0
            example_groups = @world.example_groups.ordered
            example_groups.map { |g|
              status = g.run(reporter)
              example_groups_ran += 1
              status
            }.all? ? 0 : @configuration.failure_exit_code
          ensure
            STDERR.puts %Q{
 !!!
 !!! Warning! Not all example groups completed!
 !!!
 !!! Only #{example_groups_ran} of #{example_groups.size} example groups managed to complete.
 !!!
 !!! This may mean that you have `return` statement somewhere in your examples.
 !!! Beware that `return` will not return from your example, but instead from
 !!! your example runner, causing abnormal termination of your spec suite!
 !!!
 !!! Do not do this:
 !!!
 !!! it "should do something" do
 !!!   # `return` will cause it to fail!
 !!!   return unless some_condition
 !!!   raise "test failed"
 !!! end
 !!!
            } if example_groups_ran != example_groups.size
            @configuration.run_hook(:after, :suite)
          end
        end
      end
    end
  end
end
