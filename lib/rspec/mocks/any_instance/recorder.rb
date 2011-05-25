module RSpec
  module Mocks
    module AnyInstance
      
      class Recorder
        
        def initialize(class_to_record)
          @class, @chains = class_to_record, Chains.new
        end

        def stub(method_name, *args, &block)
          add_chain Stub.new(method_name, *args, &block)
        end

        def should_receive(method_name, *args, &block)
          add_chain Expectation.new(method_name, *args, &block)
        end
      
        def playback(instance, chain_id, *args, &block)
          player          = Player.new
          player.chains   = @chains
          player.chain_id = chain_id
          player.instance = instance
          player.args     = args
          player.block    = block
          player.play
        end

        def verify
          if unfulfilled_expectations.any?
            raise MockExpectationError,
                  "Exactly one instance should have received the following message(s) but didn't: #{unfulfilled_expectation_names}"
          end
        end
        
        def remove_chains
          @chains.each {|chain| chain.restore }
        end
        
      private

        def unfulfilled_expectation_names
          unfulfilled_expectations.map {|expectation| expectation.method_name.to_s }.sort.join(', ')
        end
        
        def unfulfilled_expectations
          @chains.expectations.reject {|expectation| expectation.fulfilled? }
        end

        def add_chain(chain)      
          @chains.add chain.attach(@class)
        end

      end
      
    end
  end
end