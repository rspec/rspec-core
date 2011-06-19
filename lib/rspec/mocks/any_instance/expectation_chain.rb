module RSpec
  module Mocks
    module AnyInstance
      class ExpectationChain < Chain
        def initialize(*args, &block)
          record(:should_receive, *args, &block)
          @expectation_fulfilled = false
        end

        def invocation_order
          @invocation_order ||= {
            :should_receive => [nil],
            :with => [:should_receive],
            :and_return => [:with, :should_receive],
            :and_raise => [:with, :should_receive]
          }
        end

        def expectation_fulfilled!
          @expectation_fulfilled = true
        end

        def expectation_fulfilled?
          @expectation_fulfilled || constrained_to_any_of?(:never, :any_number_of_times)
        end

        private
        def verify_invocation_order(rspec_method_name, *args, &block)
        end
      end
    end
  end
end