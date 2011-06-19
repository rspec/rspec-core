module RSpec
  module Mocks
    module AnyInstance
      class StubChain < Chain
        def initialize(*args, &block)
          record(:stub, *args, &block)
        end

        def invocation_order
          @invocation_order ||= {
            :stub => [nil],
            :with => [:stub],
            :and_return => [:with, :stub],
            :and_raise => [:with, :stub],
            :and_yield => [:with, :stub]
          }
        end

        def expectation_fulfilled?
          true
        end
        
        def expectation_fulfilled!
        end

        private
        def verify_invocation_order(rspec_method_name, *args, &block)
          unless invocation_order[rspec_method_name].include?(last_message)
            raise(NoMethodError, "Undefined method #{rspec_method_name}")
          end
        end
      end
    end
  end
end