module RSpec
  module Core
    # Provides the main entry point to run a suite of RSpec examples.
    class Runner

      # Register an `at_exit` hook that runs the suite when the process exits.
      #
      # @note This is not generally needed. The `rspec` command takes care
      #       of running examples for you without involving an `at_exit`
      #       hook. This is only needed if you are running specs using
      #       the `ruby` command, and even then, the normal way to invoke
      #       this is by requiring `rspec/autorun`.
      def self.autorun
        if autorun_disabled?
          RSpec.deprecate("Requiring `rspec/autorun` when running RSpec via the `rspec` command")
          return
        elsif installed_at_exit? || running_in_drb?
          return
        end

        at_exit do
          # Don't bother running any specs and just let the program terminate
          # if we got here due to an unrescued exception (anything other than
          # SystemExit, which is raised when somebody calls Kernel#exit).
          next unless $!.nil? || $!.kind_of?(SystemExit)

          # We got here because either the end of the program was reached or
          # somebody called Kernel#exit.  Run the specs and then override any
          # existing exit status with RSpec's exit status if any specs failed.
          invoke
        end
        @installed_at_exit = true
      end

      # Runs the suite of specs and exits the process with an appropriate exit code.
      def self.invoke
        disable_autorun!
        status = run(ARGV, $stderr, $stdout).to_i
        exit(status) if status != 0
      end

      # Run a suite of RSpec examples. Does not exit.
      #
      # This is used internally by RSpec to run a suite, but is available
      # for use by any other automation tool.
      #
      # If you want to run this multiple times in the same process, and you
      # want files like `spec_helper.rb` to be reloaded, be sure to load `load`
      # instead of `require`.
      #
      # @param args [Array] command-line-supported arguments
      # @param err [IO] error stream
      # @param out [IO] output stream
      # @return [Fixnum] exit status code. 0 if all specs passed,
      #   or the configured failure exit code (1 by default) if specs
      #   failed.
      def self.run(args, err=$stderr, out=$stdout)
        trap_interrupt
        options = ConfigurationOptions.new(args)
        run_local = !options.options[:drb]

        unless run_local
          require 'rspec/core/drb'
          begin
            DRbRunner.new(options).run(err, out)
          rescue DRb::DRbConnError
            err.puts "No DRb server is running. Running in local process instead ..."
            run_local = true
          end
        end

        if run_local
          new(options).run(err, out)
        end
      end

      def initialize(options, configuration=RSpec.configuration, world=RSpec.world)
        @options       = options
        @configuration = configuration
        @world         = world
      end

      # Configures and runs a spec suite.
      #
      # @param err [IO] error stream
      # @param out [IO] output stream
      def run(err, out)
        setup(err, out)
        run_specs(@world.ordered_example_groups)
      end

      # Wires together the various configuration objects and state holders.
      #
      # @param err [IO] error stream
      # @param out [IO] output stream
      def setup(err, out)
        @configuration.error_stream = err
        @configuration.output_stream = out if @configuration.output_stream == $stdout
        @options.configure(@configuration)
        @configuration.load_spec_files
        @world.announce_filters
      end

      # Runs the provided example groups.
      #
      # @param example_groups [Array<RSpec::Core::ExampleGroup>] groups to run
      # @return [Fixnum] exit status code. 0 if all specs passed,
      #   or the configured failure exit code (1 by default) if specs
      #   failed.
      def run_specs(example_groups)
        @configuration.reporter.report(@world.example_count(example_groups)) do |reporter|
          begin
            hook_context = SuiteHookContext.new
            @configuration.hooks.run(:before, :suite, hook_context)
            
            group_threads = RSpec::Core::ExampleGroupThreadRunner.new
            example_groups.each { |g| group_threads.run(g, reporter, @configuration.thread_maximum) }
            group_threads.wait_for_completion

            # get results of testing now that we're done
            example_groups.all? do |g| 
              result_for_this_group = g.succeeded?
              results_for_descendants = g.children.all? { |child| child.succeeded? }
              result_for_this_group && results_for_descendants
            end ? 0 : @configuration.failure_exit_code
          ensure
            @configuration.hooks.run(:after, :suite, hook_context)
          end
        end
      end

      # @private
      def self.disable_autorun!
        @autorun_disabled = true
      end

      # @private
      def self.autorun_disabled?
        @autorun_disabled ||= false
      end

      # @private
      def self.installed_at_exit?
        @installed_at_exit ||= false
      end

      # @private
      def self.running_in_drb?
        begin
          if defined?(DRb) && DRb.current_server
            require 'socket'
            require 'uri'

            local_ipv4 = IPSocket.getaddress(Socket.gethostname)

            local_drb = ["127.0.0.1", "localhost", local_ipv4].any? { |addr| addr == URI(DRb.current_server.uri).host }
          end
        rescue DRb::DRbServerNotFound
        ensure
          return local_drb || false
        end
      end

      # @private
      def self.trap_interrupt
        trap('INT') do
          exit!(1) if RSpec.world.wants_to_quit
          RSpec.world.wants_to_quit = true
          STDERR.puts "\nExiting... Interrupt again to exit immediately."
        end
      end
    end
  end
end
