module RSpec
  module Core
    module Pending
      class SkipDeclaredInExample < StandardError; end

      # If Test::Unit is loaed, we'll use its error as baseclass, so that Test::Unit
      # will report unmet RSpec expectations as failures rather than errors.
      begin
        class PendingExampleFixedError < Test::Unit::AssertionFailedError; end
      rescue
        class PendingExampleFixedError < StandardError; end
      end

      NO_REASON_GIVEN = 'No reason given'
      NOT_YET_IMPLEMENTED = 'Not yet implemented'

      # @overload pending()
      # @overload pending(message)
      # @overload pending(message, &block)
      #
      # Stops execution of an example, and reports it as pending. Takes an
      # optional message and block.
      #
      # @param [String] message optional message to add to the summary report.
      # @param [Block] block optional block. If it fails, the example is
      #   reported as pending. If it executes cleanly the example fails.
      #
      # @example
      #
      #     describe "an example" do
      #       # reported as "Pending: no reason given"
      #       it "is pending with no message" do
      #         pending
      #         this_does_not_get_executed
      #       end
      #
      #       # reported as "Pending: something else getting finished"
      #       it "is pending with a custom message" do
      #         pending("something else getting finished")
      #         this_does_not_get_executed
      #       end
      #
      #       # reported as "Pending: something else getting finished"
      #       it "is pending with a failing block" do
      #         pending("something else getting finished") do
      #           raise "this is the failure"
      #         end
      #       end
      #
      #       # reported as failure, saying we expected the block to fail but
      #       # it passed.
      #       it "is pending with a passing block" do
      #         pending("something else getting finished") do
      #           true.should be(true)
      #         end
      #       end
      #     end
      #
      # @note `before(:each)` hooks are eval'd when you use the `pending`
      #   method within an example. If you want to declare an example `pending`
      #   and bypass the `before` hooks as well, you can pass `:pending => true`
      #   to the `it` method:
      #
      #       it "does something", :pending => true do
      #         # ...
      #       end
      #
      #   or pass `:pending => "something else getting finished"` to add a
      #   message to the summary report:
      #
      #       it "does something", :pending => "something else getting finished" do
      #         # ...
      #       end
      def pending(*args, &block)
        current_example = RSpec.current_example

        return self.class.before(:each) { pending(*args) } unless current_example

        options = args.last.is_a?(Hash) ? args.pop : {}

        if options[:unless] || (options.has_key?(:if) && !options[:if])
          return block_given? ? yield : nil
        end

        set_message! current_example, args

        current_example.metadata[:pending] = true

        if block_given?
          begin
            no_failure = false
            block.call
            no_failure = true
            current_example.metadata[:pending] = false
          rescue Exception => e
            current_example.execution_result[:exception] = e
            raise
          end

          if no_failure
            current_example.execution_result[:pending_fixed] = true
            raise PendingExampleFixedError.new
          end
        end
      end

      def skip(*args)
        current_example = RSpec.current_example

        return self.class.before(:each) { skip(*args) } unless current_example

        set_message! current_example, args

        current_example.metadata[:skip] = true

        raise SkipDeclaredInExample
      end

      def set_message!(example, args)
        message = args.first || NO_REASON_GIVEN

        example.metadata[:execution_result][:pending_message] = message
        example.execution_result[:pending_fixed] = false
      end
    end
  end
end
