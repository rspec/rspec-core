module RSpec
  module Core
    # @api private
    #
    # RSpec test suite runner
    class Runner

      # Register an at_exit hook that runs the suite.
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

      # @private
      AT_EXIT_HOOK_BACKTRACE_LINE = "#{__FILE__}:#{__LINE__ - 2}:in `autorun'"

      # Invoke the Rspec runner
      def self.invoke
        disable_autorun!
        status = run(ARGV, $stderr, $stdout).to_i
        exit(status) if status != 0
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
      def self.run(args, err=$stderr, out=$stdout)
        trap_interrupt
        options = ConfigurationOptions.new(args)

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
    end
  end
end
