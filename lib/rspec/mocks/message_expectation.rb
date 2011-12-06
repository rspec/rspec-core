module RSpec
  module Mocks

    class MessageExpectation
      # @private
      attr_reader :sym
      attr_writer :expected_received_count, :method_block, :expected_from
      protected :expected_received_count=, :method_block=, :expected_from=
      attr_accessor :error_generator
      protected :error_generator, :error_generator=

      # @private
      def initialize(error_generator, expectation_ordering, expected_from, sym, method_block, expected_received_count=1, opts={}, &implementation)
        @error_generator = error_generator
        @error_generator.opts = opts
        @expected_from = expected_from
        @sym = sym
        @method_block = method_block
        @return_block = nil
        @actual_received_count = 0
        @expected_received_count = expected_received_count
        @args_expectation = ArgumentExpectation.new(ArgumentMatchers::AnyArgsMatcher.new)
        @consecutive = false
        @exception_to_raise = nil
        @args_to_throw = []
        @order_group = expectation_ordering
        @at_least = nil
        @at_most = nil
        @exactly = nil
        @args_to_yield = []
        @failed_fast = nil
        @args_to_yield_were_cloned = false
        @return_block = implementation
        @eval_context = nil
      end

      # @private
      def build_child(expected_from, method_block, expected_received_count, opts={})
        child = clone
        child.expected_from = expected_from
        child.method_block = method_block
        child.expected_received_count = expected_received_count
        child.clear_actual_received_count!
        new_gen = error_generator.clone
        new_gen.opts = opts
        child.error_generator = new_gen
        child.clone_args_to_yield(*@args_to_yield)
        child
      end

      # @private
      def expected_args
        @args_expectation.args
      end

      # @overload and_return(value)
      # @overload and_return(first_value, second_value)
      # @overload and_return(&block)
      #
      # Tells the object to return a value when it receives the message.  Given
      # more than one value, the first value is returned the first time the
      # message is received, the second value is returned the next time, etc,
      # etc.
      #
      # If the message is received more times than there are values, the last
      # value is received for every subsequent call.
      #
      # The block format is still supported, but is unofficially deprecated in
      # favor of just passing a block to the stub method.
      #
      # @example
      #
      #   counter.stub(:count).and_return(1)
      #   counter.count # => 1
      #   counter.count # => 1
      #
      #   counter.stub(:count).and_return(1,2,3)
      #   counter.count # => 1
      #   counter.count # => 2
      #   counter.count # => 3
      #   counter.count # => 3
      #   counter.count # => 3
      #   # etc
      #
      #   # Supported, but ...
      #   counter.stub(:count).and_return { 1 }
      #   counter.count # => 1
      #
      #   # ... this is prefered
      #   counter.stub(:count) { 1 }
      #   counter.count # => 1
      def and_return(*values, &return_block)
        Kernel::raise AmbiguousReturnError unless @method_block.nil?
        case values.size
        when 0 then value = nil
        when 1 then value = values[0]
        else
          value = values
          @consecutive = true
          @expected_received_count = values.size if !ignoring_args? &&
            @expected_received_count < values.size
        end
        @return_block = block_given? ? return_block : lambda { value }
      end

      # @overload and_raise
      # @overload and_raise(ExceptionClass)
      # @overload and_raise(exception_instance)
      #
      # Tells the object to raise an exception when the message is received.
      #
      # @note
      #
      #   When you pass an exception class, the MessageExpectation will raise
      #   an instance of it, creating it with `new`. If the exception class
      #   initializer requires any parameters, you must pass in an instance and
      #   not the class.
      #
      # @example
      #
      #   car.stub(:go).and_raise
      #   car.stub(:go).and_raise(OutOfGas)
      #   car.stub(:go).and_raise(OutOfGas.new(2, :oz))
      def and_raise(exception=Exception)
        @exception_to_raise = exception
      end

      # @overload and_throw(symbol)
      # @overload and_throw(symbol, object)
      #
      # Tells the object to throw a symbol (with the object if that form is
      # used) when the message is received.
      #
      # @example
      #
      #   car.stub(:go).and_throw(:out_of_gas)
      #   car.stub(:go).and_throw(:out_of_gas, :level => 0.1)
      def and_throw(symbol, object = nil)
        @args_to_throw << symbol
        @args_to_throw << object if object
      end

      # Tells the object to yield one or more args to a block when the message
      # is received.
      #
      # @example
      #
      #   stream.stub(:open).and_yield(StringIO.new)
      def and_yield(*args, &block)
        if @args_to_yield_were_cloned
          @args_to_yield.clear
          @args_to_yield_were_cloned = false
        end

        if block
          @eval_context = Object.new
          @eval_context.extend RSpec::Mocks::InstanceExec
          yield @eval_context
        end

        @args_to_yield << args
        self
      end

      # @private
      def matches?(sym, *args)
        @sym == sym and @args_expectation.args_match?(*args)
      end

      # @private
      def invoke(*args, &block)
        if @expected_received_count == 0
          @failed_fast = true
          @actual_received_count += 1
          @error_generator.raise_expectation_error(@sym, @expected_received_count, @actual_received_count, *args)
        end

        @order_group.handle_order_constraint self

        begin
          Kernel::raise(@exception_to_raise) unless @exception_to_raise.nil?
          Kernel::throw(*@args_to_throw) unless @args_to_throw.empty?

          default_return_val = if !@method_block.nil?
                                 invoke_method_block(*args, &block)
                               elsif !@args_to_yield.empty? || @eval_context
                                 invoke_with_yield(&block)
                               else
                                 nil
                               end

          if @consecutive
            invoke_consecutive_return_block(*args, &block)
          elsif @return_block
            invoke_return_block(*args, &block)
          else
            default_return_val
          end
        ensure
          @actual_received_count += 1
        end
      end

      # @private
      def called_max_times?
        @expected_received_count != :any && @expected_received_count > 0 &&
          @actual_received_count >= @expected_received_count
      end

      # @private
      def matches_name_but_not_args(sym, *args)
        @sym == sym and not @args_expectation.args_match?(*args)
      end

      # @private
      def verify_messages_received
        generate_error unless expected_messages_received? || failed_fast?
      rescue RSpec::Mocks::MockExpectationError => error
        error.backtrace.insert(0, @expected_from)
        Kernel::raise error
      end

      # @private
      def expected_messages_received?
        ignoring_args? || matches_exact_count? || matches_at_least_count? || matches_at_most_count?
      end

      # @private
      def ignoring_args?
        @expected_received_count == :any
      end

      # @private
      def matches_at_least_count?
        @at_least && @actual_received_count >= @expected_received_count
      end

      # @private
      def matches_at_most_count?
        @at_most && @actual_received_count <= @expected_received_count
      end

      # @private
      def matches_exact_count?
        @expected_received_count == @actual_received_count
      end

      # @private
      def similar_messages
        @similar_messages ||= []
      end

      # @private
      def advise(*args)
        similar_messages << args
      end

      # @private
      def generate_error
        if similar_messages.empty?
          @error_generator.raise_expectation_error(@sym, @expected_received_count, @actual_received_count, *@args_expectation.args)
        else
          @error_generator.raise_similar_message_args_error(self, *@similar_messages)
        end
      end

      # Constrains a stub or message expectation to invocations with specific
      # arguments.
      #
      # With a stub, if the message might be received with other args as well,
      # you should stub a default value first, and then stub or mock the same
      # message using `with` to constrain to specific arguments.
      #
      # A message expectation will fail if the message is received with different
      # arguments.
      #
      # @example
      #
      #   cart.stub(:add) { :failure }
      #   cart.stub(:add).with(Book.new(:isbn => 1934356379)) { :success }
      #   cart.add(Book.new(:isbn => 1234567890))
      #   # => :failure
      #   cart.add(Book.new(:isbn => 1934356379))
      #   # => :success
      #
      #   cart.should_receive(:add).with(Book.new(:isbn => 1934356379)) { :success }
      #   cart.add(Book.new(:isbn => 1234567890))
      #   # => failed expectation
      #   cart.add(Book.new(:isbn => 1934356379))
      #   # => passes
      def with(*args, &block)
        @return_block = block if block_given? unless args.empty?
        @args_expectation = ArgumentExpectation.new(*args, &block)
        self
      end

      # Constrain a message expectation to be received a specific number of
      # times.
      #
      # @example
      #
      #   dealer.should_recieve(:deal_card).exactly(10).times
      def exactly(n, &block)
        @method_block = block if block
        set_expected_received_count :exactly, n
        self
      end

      # Constrain a message expectation to be received at least a specific
      # number of times.
      #
      # @example
      #
      #   dealer.should_recieve(:deal_card).at_least(9).times
      def at_least(n, &block)
        @method_block = block if block
        set_expected_received_count :at_least, n
        self
      end

      # Constrain a message expectation to be received at most a specific
      # number of times.
      #
      # @example
      #
      #   dealer.should_recieve(:deal_card).at_most(10).times
      def at_most(n, &block)
        @method_block = block if block
        set_expected_received_count :at_most, n
        self
      end

      # Syntactic sugar for `exactly`, `at_least` and `at_most`
      #
      # @example
      #
      #   dealer.should_recieve(:deal_card).exactly(10).times
      #   dealer.should_recieve(:deal_card).at_least(10).times
      #   dealer.should_recieve(:deal_card).at_most(10).times
      def times(&block)
        @method_block = block if block
        self
      end


      # Allows an expected message to be received any number of times.
      def any_number_of_times(&block)
        @method_block = block if block
        @expected_received_count = :any
        self
      end

      # Expect a message not to be received at all.
      #
      # @example
      #
      #   car.should_receive(:stop).never
      def never
        @expected_received_count = 0
        self
      end

      # Expect a message to be received exactly one time.
      #
      # @example
      #
      #   car.should_receive(:go).once
      def once(&block)
        @method_block = block if block
        set_expected_received_count :exactly, 1
        self
      end

      # Expect a message to be received exactly two times.
      #
      # @example
      #
      #   car.should_receive(:go).twice
      def twice(&block)
        @method_block = block if block
        set_expected_received_count :exactly, 2
        self
      end

      # Expect messages to be received in a specific order.
      #
      # @example
      #
      #   api.should_receive(:prepare).ordered
      #   api.should_receive(:run).ordered
      #   api.should_receive(:finish).ordered
      def ordered(&block)
        @method_block = block if block
        @order_group.register(self)
        @ordered = true
        self
      end

      # @private
      def negative_expectation_for?(sym)
        return false
      end

      # @private
      def actual_received_count_matters?
        @at_least || @at_most || @exactly
      end

      # @private
      def increase_actual_received_count!
        @actual_received_count += 1
      end

      protected

      def invoke_method_block(*args, &block)
        begin
          @method_block.call(*args, &block)
        rescue => detail
          @error_generator.raise_block_failed_error(@sym, detail.message)
        end
      end

      def invoke_with_yield(&block)
        if block.nil?
          @error_generator.raise_missing_block_error @args_to_yield
        end
        value = nil
        @args_to_yield.each do |args_to_yield_this_time|
          if block.arity > -1 && args_to_yield_this_time.length != block.arity
            @error_generator.raise_wrong_arity_error args_to_yield_this_time, block.arity
          end
          value = eval_block(*args_to_yield_this_time, &block)
        end
        value
      end

      def eval_block(*args, &block)
        if @eval_context
          @eval_context.instance_exec(*args, &block)
        else
          block.call(*args)
        end
      end

      def invoke_consecutive_return_block(*args, &block)
        value = invoke_return_block(*args, &block)
        index = [@actual_received_count, value.size-1].min
        value[index]
      end

      def invoke_return_block(*args, &block)
        args << block unless block.nil?
        # Ruby 1.9 - when we set @return_block to return values
        # regardless of arguments, any arguments will result in
        # a "wrong number of arguments" error
        @return_block.arity == 0 ? @return_block.call : @return_block.call(*args)
      end

      def clone_args_to_yield(*args)
        @args_to_yield = args.clone
        @args_to_yield_were_cloned = true
      end

      def failed_fast?
        @failed_fast
      end

      def set_expected_received_count(relativity, n)
        @at_least = (relativity == :at_least)
        @at_most = (relativity == :at_most)
        @exactly = (relativity == :exactly)
        @expected_received_count = case n
                                   when Numeric
                                     n
                                   when :once
                                     1
                                   when :twice
                                     2
                                   end
      end

      def clear_actual_received_count!
        @actual_received_count = 0
      end
    end

    # @private
    class NegativeMessageExpectation < MessageExpectation
      # @private
      def initialize(message, expectation_ordering, expected_from, sym, method_block)
        super(message, expectation_ordering, expected_from, sym, method_block, 0)
      end

      # @private
      def negative_expectation_for?(sym)
        return @sym == sym
      end
    end
  end
end
