require 'rspec/core'
require 'rspec/retry/version'
require 'rspec_ext/rspec_ext'
require 'optparse'

 module RSpec
  module Core
    class ConfigurationOverlay < Configuration
      def with_suite_hooks(retries)
        return yield if dry_run?

         begin
          run_suite_hooks("a `before(:suite)` hook", @before_suite_hooks, retries)
          yield
        ensure
          run_suite_hooks("an `after(:suite)` hook", @after_suite_hooks)
        end
      end

       def run_suite_hooks(hook_description, hooks, retries = 3)
        context = SuiteHookContext.new(hook_description, reporter)

         hooks.each do |hook|
          hook_remaining_retries = try_to_execute_hook(hook, context, retries)
          # Do not run subsequent `before` hooks if one fails.
          # But for `after` hooks, we run them all so that all
          # cleanup bits get a chance to complete, minimizing the
          # chance that resources get left behind.
          if hooks.equal?(@before_suite_hooks) and hook_remaining_retries == 0
            break
          end
        end
      end

       def try_to_execute_hook(hook, context, retries)
        if retries > 0
          begin
            hook.run(context, retries)
          rescue Net::ReadTimeout => ex
            context.set_exception(ex)
            log_info("There was a Net::ReadTimeout exception: " + ex.to_s)
            refresh_page
            try_to_execute_hook(hook, context, retries - 1)
          rescue Support::AllExceptionsExceptOnesWeMustNotRescue => ex
            context.set_exception(ex)
            refresh_page
            try_to_execute_hook(hook, context, retries - 1)
          end
        end

         retries
      end
    end
  end
end

 # rubocop:disable Style/CaseEquality
module RSpec
  module Core
    # Provides `before`, `after` and `around` hooks as a means of
    # supporting common setup and teardown. This module is extended
    # onto {ExampleGroup}, making the methods available from any `describe`
    # or `context` block and included in {Configuration}, making them
    # available off of the configuration object to define global setup
    # or teardown logic.
    module Hooks
      def run(context, retries)
        loop do
          if attempts > 0
            RSpec.configuration.formatters.each { |f| f.retry(example) if f.respond_to? :retry }
            if verbose_retry?
              message = "RSpec::Retry: #{ordinalize(attempts + 1)} try #{example.location}"
              message = "\n" + message if attempts == 1
              RSpec.configuration.reporter.message(message)
            end
          end

           example.metadata[:retry_attempts] = attempts

           example.clear_exception
          ex.run

           self.attempts += 1

           break if example.exception.nil?

           break if attempts >= retry_count

           if exceptions_to_hard_fail.any?
            break if exception_exists_in?(exceptions_to_hard_fail, example.exception)
          end

           if exceptions_to_retry.any?
            break unless exception_exists_in?(exceptions_to_retry, example.exception)
          end

           if verbose_retry? && display_try_failure_messages?
            if attempts != retry_count
              exception_strings =
                if ::RSpec::Core::MultipleExceptionError::InterfaceTag === example.exception
                  example.exception.all_exceptions.map(&:to_s)
                else
                  [example.exception.to_s]
                end

               try_message = "\n#{ordinalize(attempts)} Try error in #{example.location}:\n#{exception_strings.join "\n"}\n"
              RSpec.configuration.reporter.message(try_message)
            end
          end

           example.example_group_instance.clear_lets if clear_lets

           # If the callback is defined, let's call it
          if RSpec.configuration.retry_callback
            example.example_group_instance.instance_exec(example, &RSpec.configuration.retry_callback)
          end

           sleep sleep_interval if sleep_interval.to_f > 0
        end
      end
    end
  end
end
# rubocop:enable Style/CaseEquality

 module RSpec
  module Core
    # Provides the main entry point to run a suite of RSpec examples.
    class RunnerRetry < Runner
      # Runs the suite of specs and exits the process with an appropriate exit
      # code.
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
      def self.run(args, err = $stderr, out = $stdout)
        trap_interrupt
        options = ConfigurationOptions.new(args)

         if options.options[:runner]
          options.options[:runner].call(options, err, out)
        else
          new(options).run_with_retries(err, out, 3)
        end
      end

       def run_with_retries(err, out, retries)
        setup(err, out)
        run_specs_with_retries(@world.ordered_example_groups, retries).tap do
          persist_example_statuses
        end
      end

       def run_specs_with_retries(example_groups, retries)
        examples_count = @world.example_count(example_groups)
        success = @configuration.reporter.report(examples_count) do |reporter|
          @configuration.with_suite_hooks_retries(retries) do
            if examples_count == 0 && @configuration.fail_if_no_examples
              return @configuration.failure_exit_code
            end

             example_groups.map { |g| g.run_with_retries(reporter, retries) }.all?
          end
        end && !@world.non_example_failure

         success ? 0 : @configuration.failure_exit_code
      end
    end
  end
end

 module RSpec
  module Core
    class ExampleGroup
      # Runs all the examples in this group.
      def self.run_with_retries(reporter = RSpec::Core::NullReporter, retries)
        return if RSpec.world.wants_to_quit
        reporter.example_group_started(self)

         should_run_context_hooks = descendant_filtered_examples.any?
        begin
          run_before_context_hooks_with_retries(new('before(:context) hook'), retries) if should_run_context_hooks
          result_for_this_group = run_examples(reporter)
          results_for_descendants = ordering_strategy.order(children).map { |child| child.run(reporter) }.all?
          result_for_this_group && results_for_descendants
        rescue Pending::SkipDeclaredInExample => ex
          for_filtered_examples(reporter) { |example| example.skip_with_exception(reporter, ex) }
          true
        rescue Support::AllExceptionsExceptOnesWeMustNotRescue => ex
          for_filtered_examples(reporter) { |example| example.fail_with_exception(reporter, ex) }
          RSpec.world.wants_to_quit = true if reporter.fail_fast_limit_met?
          false
        ensure
          run_after_context_hooks(new('after(:context) hook')) if should_run_context_hooks
          reporter.example_group_finished(self)
        end
      end

       def self.run_before_context_hooks_with_retries(example_group_instance, retries)
        set_ivars(example_group_instance, superclass_before_context_ivars)

         @currently_executing_a_context_hook = true

         ContextHookMemoized::Before.isolate_for_context_hook(example_group_instance) do
          hooks.run_with_retries(:before, :context, example_group_instance, retries)
        end
      ensure
        store_before_context_ivars(example_group_instance)
        @currently_executing_a_context_hook = false
      end
    end
  end
end

 # rubocop:disable Lint/RescueException
module RSpec
  module Core
    module Hooks
      class BeforeHook < Hook
        def run_with_retries(example, retries)
          example.instance_exec(example, &block)
        rescue Exception => e
          raise "Issue after #{RETRY_COUNT} number of retries: #{e}" if retries == 1
          Capybara.reset!
          run_with_retries(example, retries - 1)
        end
      end

       class HookCollections
        # Runs all of the blocks stored with the hook in the context of the
        # example. If no example is provided, just calls the hook directly.
        def run_with_retries(position, scope, example_or_group, retries)
          return if RSpec.configuration.dry_run?

           if scope == :context
            unless example_or_group.class.metadata[:skip]
              run_owned_hooks_with_retries_for(position, :context, example_or_group, retries)
            end
          else
            case position
            when :before then run_example_hooks_with_retries_for(example_or_group, :before, :reverse_each, retries)
            when :after  then run_example_hooks_for(example_or_group, :after,  :each)
            when :around then run_around_example_hooks_for(example_or_group) { yield }
            end
          end
        end

         def run_example_hooks_with_retries_for(example, position, each_method, retries)
          owner_parent_groups.__send__(each_method) do |group|
            group.hooks.run_owned_hooks_with_retries_for(position, :example, example, retries)
          end
        end

         def run_owned_hooks_with_retries_for(position, scope, example_or_group, retries)
          matching_hooks_for(position, scope, example_or_group).each do |hook|
            hook.run_with_retries(example_or_group, retries)
          end
        end
      end
    end
  end
end
# rubocop:enable Lint/RescueException

 # rubocop:disable Style/ClassAndModuleChildren
module RSpec::Core
  class ParserWithRetries < Parser
    def self.parse(args, source = nil)
      new(args).parse(source)
    end

     attr_reader :original_args

     def initialize(original_args)
      @original_args = original_args
    end

     def parse_with_retries(source = nil)
      return { :files_or_directories_to_run => [] } if original_args.empty?
      args = original_args.dup

       options = args.delete('--tty') ? { :tty => true } : {}
      begin
        parser_with_retries(options).parse!(args)
      rescue OptionParser::InvalidOption => e
        failure = e.message
        failure << " (defined in #{source})" if source
        abort "#{failure}\n\nPlease use --help for a listing of valid options"
      end

       options[:files_or_directories_to_run] = args
      options
    end

     private

     def parser_with_retries(options)
      OptionParser.new do |parser|
        parser.summary_width = 34

         parser.banner = "Usage: rspec [options] [files or directories]\n\n"

         parser.on('-I PATH', 'Specify PATH to add to $LOAD_PATH (may be used more than once).') do |dirs|
          options[:libs] ||= []
          options[:libs].concat(dirs.split(File::PATH_SEPARATOR))
        end

         parser.on('-r', '--require PATH', 'Require a file.') do |path|
          options[:requires] ||= []
          options[:requires] << path
        end

         parser.on('-O', '--options PATH', 'Specify the path to a custom options file.') do |path|
          options[:custom_options_file] = path
        end

         parser.on('--order TYPE[:SEED]', 'Run examples by the specified order type.',
          '  [defined] examples and groups are run in the order they are defined',
          '  [rand]    randomize the order of groups and examples',
          '  [random]  alias for rand',
          '  [random:SEED] e.g. --order random:123') do |o|
          options[:order] = o
        end

         parser.on('--seed SEED', Integer, 'Equivalent of --order rand:SEED.') do |seed|
          options[:order] = "rand:#{seed}"
        end

         parser.on('--bisect[=verbose]', 'Repeatedly runs the suite in order to isolate the failures to the ',
          '  smallest reproducible case.') do |argument|
          options[:bisect] = argument || true
          options[:runner] = RSpec::Core::Invocations::Bisect.new
        end

         parser.on('--[no-]fail-fast[=COUNT]', 'Abort the run after a certain number of failures (1 by default).') do |argument|
          if argument == true
            value = 1
          elsif argument == false || argument == 0
            value = false
          else
            begin
              value = Integer(argument)
            rescue ArgumentError
              RSpec.warning "Expected an integer value for `--fail-fast`, got: #{argument.inspect}", :call_site => nil
            end
          end
          set_fail_fast(options, value)
        end

         parser.on('--failure-exit-code CODE', Integer,
          'Override the exit code used when there are failing specs.') do |code|
          options[:failure_exit_code] = code
        end

         parser.on('-X', '--[no-]drb', 'Run examples via DRb.') do |use_drb|
          options[:drb] = use_drb
          options[:runner] = RSpec::Core::Invocations::DRbWithFallbackWithRetries.new if use_drb
        end

         parser.on('--drb-port PORT', 'Port to connect to the DRb server.') do |o|
          options[:drb_port] = o.to_i
        end

         parser.separator("\n  **** Output ****\n\n")

         parser.on('-f', '--format FORMATTER', 'Choose a formatter.',
          '  [p]rogress (default - dots)',
          '  [d]ocumentation (group and example names)',
          '  [h]tml',
          '  [j]son',
          '  custom formatter class name') do |o|
          options[:formatters] ||= []
          options[:formatters] << [o]
        end

         parser.on('-o', '--out FILE',
          'Write output to a file instead of $stdout. This option applies',
          '  to the previously specified --format, or the default format',
          '  if no format is specified.'
        ) do |o|
          options[:formatters] ||= [['progress']]
          options[:formatters].last << o
        end

         parser.on('--deprecation-out FILE', 'Write deprecation warnings to a file instead of $stderr.') do |file|
          options[:deprecation_stream] = file
        end

         parser.on('-b', '--backtrace', 'Enable full backtrace.') do |_o|
          options[:full_backtrace] = true
        end

         parser.on('-c', '--color', '--colour', '') do |_o|
          # flag will be excluded from `--help` output because it is deprecated
          options[:color] = true
          options[:color_mode] = :automatic
        end

         parser.on('--force-color', '--force-colour', 'Force the output to be in color, even if the output is not a TTY') do |_o|
          if options[:color_mode] == :off
            abort "Please only use one of `--force-color` and `--no-color`"
          end
          options[:color_mode] = :on
        end

         parser.on('--no-color', '--no-colour', 'Force the output to not be in color, even if the output is a TTY') do |_o|
          if options[:color_mode] == :on
            abort "Please only use one of --force-color and --no-color"
          end
          options[:color_mode] = :off
        end

         parser.on('-p', '--[no-]profile [COUNT]',
          'Enable profiling of examples and list the slowest examples (default: 10).') do |argument|
          options[:profile_examples] =
            if argument.nil?
              true
            elsif argument == false
              false
            else
              begin
                Integer(argument)
              rescue ArgumentError
                RSpec.warning "Non integer specified as profile count, separate " \
                            "your path from options with -- e.g. " \
                            "`rspec --profile -- #{argument}`",
                  :call_site => nil
                true
              end
            end
        end

         parser.on('--dry-run', 'Print the formatter output of your suite without',
          '  running any examples or hooks') do |_o|
          options[:dry_run] = true
        end

         parser.on('-w', '--warnings', 'Enable ruby warnings') do
          $VERBOSE = true
        end

         parser.separator <<-FILTERING
  **** Filtering/tags ****
    In addition to the following options for selecting specific files, groups, or
    examples, you can select individual examples by appending the line number(s) to
    the filename:
      rspec path/to/a_spec.rb:37:87
    You can also pass example ids enclosed in square brackets:
      rspec path/to/a_spec.rb[1:5,1:6] # run the 5th and 6th examples/groups defined in the 1st group
        FILTERING

         parser.on('--only-failures', "Filter to just the examples that failed the last time they ran.") do
          configure_only_failures(options)
        end

         parser.on("-n", "--next-failure", "Apply `--only-failures` and abort after one failure.",
          "  (Equivalent to `--only-failures --fail-fast --order defined`)") do
          configure_only_failures(options)
          set_fail_fast(options, 1)
          options[:order] ||= 'defined'
        end

         parser.on('-P', '--pattern PATTERN', 'Load files matching pattern (default: "spec/**/*_spec.rb").') do |o|
          if options[:pattern]
            options[:pattern] += ',' + o
          else
            options[:pattern] = o
          end
        end

         parser.on('--exclude-pattern PATTERN',
          'Load files except those matching pattern. Opposite effect of --pattern.') do |o|
          options[:exclude_pattern] = o
        end

         parser.on('-e', '--example STRING', "Run examples whose full nested names include STRING (may be",
          "  used more than once)") do |o|
          (options[:full_description] ||= []) << Regexp.compile(Regexp.escape(o))
        end

         parser.on('-t', '--tag TAG[:VALUE]',
          'Run examples with the specified tag, or exclude examples',
          'by adding ~ before the tag.',
          '  - e.g. ~slow',
          '  - TAG is always converted to a symbol') do |tag|
          filter_type = /^~/.match?(tag) ? :exclusion_filter : :inclusion_filter

           name, value = tag.gsub(/^(~@|~|@)/, '').split(':', 2)
          name = name.to_sym

           parsed_value =
            case value
            when nil then true # The default value for tags is true
            when 'true'      then true
            when 'false'     then false
            when 'nil'       then nil
            when /^:/        then value[1..-1].to_sym
            when /^\d+$/     then Integer(value)
            when /^\d+.\d+$/ then Float(value)
            else
              value
            end

           add_tag_filter(options, filter_type, name, parsed_value)
        end

         parser.on('--default-path PATH', 'Set the default path where RSpec looks for examples (can',
          '  be a path to a file or a directory).') do |path|
          options[:default_path] = path
        end

         parser.separator("\n  **** Utility ****\n\n")

         parser.on('--init', 'Initialize your project with RSpec.') do |_cmd|
          options[:runner] = RSpec::Core::Invocations::InitializeProject.new
        end

         parser.on('-v', '--version', 'Display the version.') do
          options[:runner] = RSpec::Core::Invocations::PrintVersion.new
        end

         # These options would otherwise be confusing to users, so we forcibly
        # prevent them from executing.
        #
        #   * --I is too similar to -I.
        #   * -d was a shorthand for --debugger, which is removed, but now would
        #     trigger --default-path.
        invalid_options = %w[-d --I]

         hidden_options = invalid_options + %w[-c]

         parser.on_tail('-h', '--help', "You're looking at it.") do
          options[:runner] = RSpec::Core::Invocations::PrintHelp.new(parser, hidden_options)
        end

         # This prevents usage of the invalid_options.
        invalid_options.each do |option|
          parser.on(option) do
            raise OptionParser::InvalidOption
          end
        end
      end
    end
  end
end
# rubocop:enable Style/ClassAndModuleChildren

 module RSpec
  module Core
    # @private
    module Invocations
      class DRbWithFallbackWithRetries
        def call(options, err, out)
          require 'rspec/core/drb'
          begin
            return DRbRunner.new(options).run(err, out)
          rescue DRb::DRbConnError
            err.puts "No DRb server is running. Running in local process instead ..."
          end
          RSpec::Core::RunnerRetry.new(options).run_with_retries(err, out, 3)
        end
      end
    end
  end
end

 module RSpec
  module Core
    class ConfigurationOptionsRetries < ConfigurationOptions
      def initialize(args)
        @args = args.dup
        organize_options_with_retries
      end

       private

       def organize_options_with_retries
        @filter_manager_options = []

         #@before_suite_hooks << Hooks::BeforeHook.new(block, {})

         @options = (file_options << command_line_options_with_retries << env_options).each do |opts|
          @filter_manager_options << [:include, opts.delete(:inclusion_filter)] if opts.key?(:inclusion_filter)
          @filter_manager_options << [:exclude, opts.delete(:exclusion_filter)] if opts.key?(:exclusion_filter)
        end

         @options = @options.inject(:libs => [], :requires => []) do |hash, opts|
          hash.merge(opts) do |key, oldval, newval|
            [:libs, :requires].include?(key) ? oldval + newval : newval
          end
        end
      end

       def command_line_options_with_retries
        @command_line_options ||= ParserWithRetries.parse(@args)
      end
    end
  end
end
