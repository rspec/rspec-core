module RSpec
  module Mocks
    module AnyInstance

      # @private
      class ExpectationChain < Chain

        # @private
        def initialize(*args, &block)
          record(:should_receive, *args, &block)
          @expectation_fulfilled = false
        end

        # @private
        def expectation_fulfilled?
          @expectation_fulfilled || constrained_to_any_of?(:never, :any_number_of_times)
        end

        private

        def verify_invocation_order(rspec_method_name, *args, &block)
        end

        def invocation_order
          @invocation_order ||= {
            :should_receive => [nil],
            :with => [:should_receive],
            :and_return => [:with, :should_receive],
            :and_raise => [:with, :should_receive]
          }
        end
      end
    end
  end
end