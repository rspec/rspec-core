module RSpec
  module Mocks
    module AnyInstance
      class MessageChains < Hash
        def add(method_name, chain)
          (self[method_name] ||= []) << chain
        end
        
        def remove_stub_chains_for!(method_name)
          chains = self[method_name]
          chains.reject! { |chain| chain.is_a?(StubChain) || chain.is_a?(StubChainChain) }
        end
        
        def has_expectation?(method_name)
          !!self[method_name].find{|chain| chain.is_a?(ExpectationChain)}
        end
        
        def each_expectation_fulfilled?
          self.all? do |method_name, chains|
            chains.all? { |chain| chain.expectation_fulfilled? }
          end
        end

        def unfulfilled_expectations
          self.map do |method_name, chains|
            method_name.to_s if chains.last.is_a?(ExpectationChain) unless chains.last.expectation_fulfilled?
          end.compact
        end

        def received_expected_message!(method_name)
          self[method_name].each do |chain|
            chain.expectation_fulfilled!
          end
        end
        
        def playback!(instance, method_name)
          self[method_name].each do |chain|
            @instance_with_expectation = instance if instance.is_a?(ExpectationChain) && !@instance_with_expectation
            if instance.is_a?(ExpectationChain) && !@instance_with_expectation.equal?(instance)
              raise RSpec::Mocks::MockExpectationError, "Exactly one instance should have received the following message(s) but didn't: #{unfulfilled_expectations.sort.join(', ')}"
            end
            chain.playback!(instance)
          end
        end
      end
    end
  end
end