module RSpec
  module Mocks
    module AnyInstance
      class StubChainChain < Chain
        def initialize(*args, &block)
          record(:stub_chain, *args, &block)
        end

        def invocation_order
          @invocation_order ||= {
            :stub_chain => [nil],
            :and_return => [:stub_chain],
            :and_raise => [:stub_chain],
            :and_yield => [:stub_chain]
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