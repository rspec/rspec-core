module RSpec
  module Core
    # Wrapper for an instance of a subclass of {ExampleGroup}. An instance of
    # `Example` is returned by the {ExampleGroup#example example} method
    # exposed to examples, {Hooks#before before} and {Hooks#after after} hooks,
    # and yielded to {Hooks#around around} hooks.
    #
    # Useful for configuring logging and/or taking some action based
    # on the state of an example's metadata.
    #
    # @example
    #
    #     RSpec.configure do |config|
    #       config.before do
    #         log example.description
    #       end
    #
    #       config.after do
    #         log example.description
    #       end
    #
    #       config.around do |ex|
    #         log example.description
    #         ex.run
    #       end
    #     end
    #
    #     shared_examples "auditable" do
    #       it "does something" do
    #         log "#{example.full_description}: #{auditable.inspect}"
    #         auditable.should do_something
    #       end
    #     end
    #
    # @see ExampleGroup
    class Example
      # @private
      #
      # Used to define methods that delegate to this example's metadata
      def self.delegate_to_metadata(*keys)
        keys.each { |key| define_method(key) { @metadata[key] } }
      end

      delegate_to_metadata :full_description, :execution_result, :file_path, :pending, :location

      # Returns the string submitted to `example` or its aliases (e.g.
      # `specify`, `it`, etc).  If no string is submitted (e.g. `it { should
      # do_something }`) it returns the message generated by the matcher if
      # there is one, otherwise returns a message including the location of the
      # example.
      def description
        description = metadata[:description].to_s.empty? ? "example at #{location}" : metadata[:description]
        RSpec.configuration.format_docstrings_block.call(description)
      end

      # @attr_reader
      #
      # Returns the first exception raised in the context of running this
      # example (nil if no exception is raised)
      attr_reader :exception

      # @attr_reader
      #
      # Returns the metadata object associated with this example.
      attr_reader :metadata

      # @attr_reader
      # @private
      #
      # Returns the example_group_instance that provides the context for
      # running this example.
      attr_reader :example_group_instance

      # Creates a new instance of Example.
      # @param example_group_class the subclass of ExampleGroup in which this Example is declared
      # @param description the String passed to the `it` method (or alias)
      # @param metadata additional args passed to `it` to be used as metadata
      # @param example_block the block of code that represents the example
      def initialize(example_group_class, description, metadata, example_block=nil)
        @example_group_class, @options, @example_block = example_group_class, metadata, example_block
        @metadata  = @example_group_class.metadata.for_example(description, metadata)
        @exception = nil
        @pending_declared_in_example = false
      end

      # @deprecated access options via metadata instead
      def options
        @options
      end

      # Returns the example group class that provides the context for running
      # this example.
      def example_group
        @example_group_class
      end

      alias_method :pending?, :pending

      # @api private
      # instance_evals the block passed to the constructor in the context of
      # the instance of {ExampleGroup}.
      # @param example_group_instance the instance of an ExampleGroup subclass
      def run(example_group_instance, reporter)
        @example_group_instance = example_group_instance
        @example_group_instance.example = self

        start(reporter)

        begin
          unless pending
            with_around_each_hooks do
              begin
                run_before_each
                @example_group_instance.instance_eval(&@example_block)
              rescue ExampleInterrupted, Pending::PendingDeclaredInExample => e
                @pending_declared_in_example = e.message
              rescue Exception => e
                set_exception(e)
              ensure
                run_after_each
              end
            end
          end
        rescue Exception => e
          set_exception(e)
        ensure
          @example_group_instance.instance_variables.each do |ivar|
            @example_group_instance.instance_variable_set(ivar, nil)
          end
          @example_group_instance = nil

          begin
            assign_generated_description
          rescue Exception => e
            set_exception(e, "while assigning the example description")
          end
        end

        finish(reporter)
      end

      # @api private
      #
      # Wraps the example block in a Proc so it can invoked using `run` or
      # `call` in [around](../Hooks#around-instance_method) hooks.
      def self.procsy(metadata, &proc)
        proc.extend(Procsy).with(metadata)
      end

      # Used to extend a `Proc` with behavior that makes it look something like
      # an {Example} in an {Hooks#around around} hook.
      #
      # @note Procsy, itself, is not a public API, but we're documenting it
      #   here to document how to interact with the object yielded to an
      #   `around` hook.
      #
      # @example
      #
      #     RSpec.configure do |c|
      #       c.around do |ex| # ex is a Proc extended with Procsy
      #         if ex.metadata[:key] == :some_value && some_global_condition
      #           raise "some message"
      #         end
      #         ex.run         # run delegates to ex.call
      #       end
      #     end
      module Procsy
        # The `metadata` of the {Example} instance.
        attr_reader :metadata

        # @api private
        # @param [Proc]
        # Adds a `run` method to the extended Proc, allowing it to be invoked
        # in an [around](../Hooks#around-instance_method) hook using either
        # `run` or `call`.
        def self.extended(proc)
          # @api public
          # Foo bar
          def proc.run; call; end
        end

        # @api private
        def with(metadata)
          @metadata = metadata
          self
        end
      end

      # @private
      def any_apply?(filters)
        metadata.any_apply?(filters)
      end

      # @private
      def all_apply?(filters)
        @metadata.all_apply?(filters) || @example_group_class.all_apply?(filters)
      end

      # @private
      def around_each_hooks
        @around_each_hooks ||= example_group.around_each_hooks_for(self)
      end

      # @private
      #
      # Used internally to set an exception in an after hook, which
      # captures the exception but doesn't raise it.
      def set_exception(exception, context=nil)
        if @exception && context != :dont_print
          # An error has already been set; we don't want to override it,
          # but we also don't want silence the error, so let's print it.
          msg = <<-EOS

An error occurred #{context}
  #{exception.class}: #{exception.message}
  occurred at #{exception.backtrace.first}

          EOS
          RSpec.configuration.reporter.message(msg)
        end

        @exception ||= exception
      end

      # @private
      #
      # Used internally to set an exception and fail without actually executing
      # the example when an exception is raised in before(:all).
      def fail_with_exception(reporter, exception)
        start(reporter)
        set_exception(exception)
        finish(reporter)
      end

      # @private
      def instance_eval(*args, &block)
        @example_group_instance.instance_eval(*args, &block)
      end

      # @private
      def instance_eval_with_rescue(context = nil, &block)
        @example_group_instance.instance_eval_with_rescue(context, &block)
      end

      # @private
      def instance_eval_with_args(*args, &block)
        @example_group_instance.instance_eval_with_args(*args, &block)
      end

    private

      def with_around_each_hooks(&block)
        if around_each_hooks.empty?
          yield
        else
          @example_group_class.run_around_each_hooks(self, Example.procsy(metadata, &block))
        end
      rescue Exception => e
        set_exception(e, "in an around(:each) hook")
      end

      def start(reporter)
        reporter.example_started(self)
        record :started_at => RSpec::Core::Time.now
      end

      # @private
      module NotPendingExampleFixed
        def pending_fixed?; false; end
      end

      def finish(reporter)
        if @exception
          @exception.extend(NotPendingExampleFixed) unless @exception.respond_to?(:pending_fixed?)
          record_finished 'failed', :exception => @exception
          reporter.example_failed self
          false
        elsif @pending_declared_in_example
          record_finished 'pending', :pending_message => @pending_declared_in_example
          reporter.example_pending self
          true
        elsif pending
          record_finished 'pending', :pending_message => String === pending ? pending : Pending::NO_REASON_GIVEN
          reporter.example_pending self
          true
        else
          record_finished 'passed'
          reporter.example_passed self
          true
        end
      end

      def record_finished(status, results={})
        finished_at = RSpec::Core::Time.now
        record results.merge(:status => status, :finished_at => finished_at, :run_time => (finished_at - execution_result[:started_at]).to_f)
      end

      def run_before_each
        set_interrupt_trap
        @example_group_instance.setup_mocks_for_rspec
        @example_group_class.run_before_each_hooks(self)
      end

      def run_after_each
        unset_interrupt_trap
        @example_group_class.run_after_each_hooks(self)
        verify_mocks
      rescue Exception => e
        set_exception(e, "in an after(:each) hook")
      ensure
        @example_group_instance.teardown_mocks_for_rspec
      end

      def set_interrupt_trap
        if trap_type = RSpec.configuration.skip_example_trap
          trap(trap_type[:signal]) { raise ExampleInterrupted.new(trap_type[:message]) }
        end
      end

      def unset_interrupt_trap
        if trap_type = RSpec.configuration.skip_example_trap
          trap(trap_type[:signal], 'DEFAULT')
        end
      end

      def verify_mocks
        @example_group_instance.verify_mocks_for_rspec
      rescue Exception => e
        set_exception(e, :dont_print)
      end

      def assign_generated_description
        return unless RSpec.configuration.expecting_with_rspec?
        if metadata[:description_args].empty? and !pending?
          metadata[:description_args] << RSpec::Matchers.generated_description
        end
        RSpec::Matchers.clear_generated_description
      end

      def record(results={})
        execution_result.update(results)
      end
    end

    class ExampleInterrupted < StandardError ; end
  end
end
