module RSpec
  module Core
    class Runner
      class << self
        #we need access to the main object in .set_up_dsl
        attr_accessor :main_object
      end

      def self.instance
        @instance ||= new
      end

      def self.autorun
        instance.autorun
      end

      # Register an at_exit hook that runs the suite.
      def autorun
        return if installed_at_exit? || running_in_drb?

        configure_and_set_up(ARGV)
        at_exit do
          # Don't bother running any specs and just let the program terminate
          # if we got here due to an unrescued exception (anything other than
          # SystemExit, which is raised when somebody calls Kernel#exit).
          next unless $!.nil? || $!.kind_of?(SystemExit)

          # We got here because either the end of the program was reached or
          # somebody called Kernel#exit.  Run the specs and then override any
          # existing exit status with RSpec's exit status if any specs failed.
          status = run.to_i
          exit status if status != 0
        end
        @installed_at_exit = true
      end
      AT_EXIT_HOOK_BACKTRACE_LINE = "#{__FILE__}:#{__LINE__ - 2}:in `autorun'"

      def running_in_drb?
        defined?(DRb) &&
        (DRb.current_server rescue false) &&
         DRb.current_server.uri =~ /druby\:\/\/127.0.0.1\:/
      end

      # Run a suite of RSpec examples.
      #
      # This is used internally by RSpec to run a suite, but is available
      # for use by any other automation tool.
      #
      # If you want to run this multiple times in the same process, and you
      # want files like spec_helper.rb to be reloaded, be sure to load `load`
      # instead of `require`.
      #
      # #### Parameters
      # * +args+ - an array of command-line-supported arguments
      # * +err+ - error stream (Default: $stderr)
      # * +out+ - output stream (Default: $stdout)
      #
      # #### Returns
      # * +Fixnum+ - exit status code (0/1)
      def self.run(*args)
        instance.run(*args)
      end

      def run(args=[], err=$stderr, out=$stdout)
        trap_interrupt
        configure_and_set_up(args)

        if options.options[:drb]
          require 'rspec/core/drb_command_line'
          begin
            DRbCommandLine.new(options).run(err, out)
          rescue DRb::DRbConnError
            err.puts "No DRb server is running. Running in local process instead ..."
            CommandLine.new(options).run(err, out)
          end
        else
          CommandLine.new(options).run(err, out)
        end
      ensure
        RSpec.reset
      end

      private
      def options
        @options
      end

      def installed_at_exit?
        @installed_at_exit ||= false
      end

      def trap_interrupt
        trap('INT') do
          exit!(1) if RSpec.wants_to_quit
          RSpec.wants_to_quit = true
          STDERR.puts "\nExiting... Interrupt again to exit immediately."
        end
      end

      def set_up_dsl
        return if !options.options[:toplevel_dsl] || @dsl_setup_done

        self.class.main_object.send(:extend, RSpec::Core::DSL)
        Module.send(:include, RSpec::Core::DSL)
        @dsl_setup_done = true
      end

      def configure_and_set_up(args)
        return if args.empty? && !@options.nil?
        @options = begin
          options = ConfigurationOptions.new(args)
          options.parse_options

          options
        end

        set_up_dsl
      end
    end
  end
end

RSpec::Core::Runner.main_object = self

