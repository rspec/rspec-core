require 'thread'

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
      # @param [int] num_threads
      def run(err, out, num_threads=1)
        @configuration.error_stream = err
        @configuration.output_stream ||= out
        @options.configure(@configuration)
        @configuration.load_spec_files
        @world.announce_filters

        @configuration.reporter.report(@world.example_count, @configuration.randomize? ? @configuration.seed : nil) do |reporter|
          begin
            @configuration.run_hook(:before, :suite)
            group_threads = RSpec::Core::ExampleGroupThreads.new
            @world.example_groups.ordered.map {|g| 
              group_threads.run_example_group_as_thread(g, reporter, num_threads)
            }

            # wait for example_groups to complete
            group_threads.wait_for_completion

            # get results of testing now that we're done
            @world.example_groups.ordered.map { |g| 
              reporter.example_group_started(g)
              result_for_this_group = g.succeeded?
              results_for_descendants = g.children.ordered.map {|child| child.succeeded? }.all?
              reporter.example_group_finished(g)
              result_for_this_group && results_for_descendants
            }.all? ? 0 : @configuration.failure_exit_code
          ensure
            @configuration.run_hook(:after, :suite)
          end
        end
      end
    end

    class ExampleThreads
      attr_accessor :num_threads, :thread_array, :fname, :lock
      def initialize(num_threads)
        @num_threads = num_threads
        # puts "Creating ExampleThreads object with #{@num_threads} threads."
        @thread_array = []
        $used_threads = $used_threads || 0
        @fname = '.examplelock'
        if !File.exists? @fname
          File.new(@fname, "a+") { |f| f.write "lock" }
        end
      end

      def wait_for_available_thread
        # puts "Global threads in use = #{$used_threads}."
        # puts "Local threads in use = #{@thread_array.length}."
        # wait for available thread if we've reached our global limit
        while $used_threads.to_i >= @num_threads.to_i
          # puts "Waiting for available thread. Running = #{$used_threads}; Max = #{@num_threads}"
          sleep 1 #0.1
        end
      end

      def run_example_as_thread(example, instance, reporter)
        # puts "Setting lock for example '#{example.description}'..."
        set_lock
        wait_for_available_thread
        @thread_array.push Thread.start {
          # puts "Starting example '#{example.description}'..."
          example.run(instance, reporter)
          # puts "Example '#{example.description}' completed."
          @thread_array.delete Thread.current # remove from local scope
          $used_threads -= 1 # remove from global scope
        }
        $used_threads += 1 # add to global scope
      ensure
        # puts "Releasing lock for example '#{example.description}'..."
        release_lock
        # puts "Lock for '#{example.description}' released."
      end

      def wait_for_completion
        # wait for threads to complete
        while @thread_array.length > 0
          # puts "Waiting for #{@thread_array.length} example threads to complete."
          sleep 1 #0.1
        end
      end

      def set_lock
        (@lock = File.new(@fname,"r+")).flock(File::LOCK_EX)
      end

      def release_lock
        @lock.flock(File::LOCK_UN)
      end
    end

    class ExampleGroupThreads
      attr_accessor :thread_array
      def initialize
        @thread_array = []
      end

      def run_example_group_as_thread(examplegroup, reporter, num_threads=1)
        @thread_array.push Thread.start {
          # puts "Starting examplegroup '#{examplegroup.description}'..."
          examplegroup.run(reporter, num_threads)
          # puts "Examplegroup '#{examplegroup.description}' completed."
          @thread_array.delete Thread.current # remove from local scope
        }
      end

      def wait_for_completion
        # wait for threads to complete
        while @thread_array.length > 0
          # puts "Waiting for #{@thread_array.length} group threads to complete."
          sleep 1 #0.1
        end
      end
    end
  end
end
