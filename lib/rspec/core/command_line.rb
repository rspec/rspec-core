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
            unless @configuration.stress_test
              @world.example_groups.ordered.map {|g| g.run(reporter)}.all?
            else
              success = true
              random = Random.new(@configuration.seed)
              all_examples = @world.all_examples
              end_time = Time.now + @configuration.stress_test
              while Time.now < end_time
                example = all_examples.sample(random: random)
                chain_to_execute = [example] + example.example_group.parent_groups.dup
                success &= chain_to_execute.pop.run(reporter, chain_to_execute)
                break if RSpec.wants_to_quit
              end
              success
            end ? 0 : @configuration.failure_exit_code
          ensure
            @configuration.run_hook(:after, :suite)
          end
        end
      end
    end
  end
end
