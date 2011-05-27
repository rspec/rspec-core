module RSpec
  module Mocks
    module AnyInstance
      
      class Recorder
        
        attr_reader :chains
        
        def initialize(class_to_record)
          @class, @chains = class_to_record, Chains.new
        end
        
        def should_receive(sym, *args, &block)
          add_chain Expectation.new(sym, *args, &block)
        end

        def stub(sym_or_hash, *args, &block)
          if Hash === sym_or_hash
            sym_or_hash.each do |method, value|
              chain = Stub.new(method, *args, &block)
              chain.add_message(:and_return, value)
              add_chain(chain)
            end
          else
            add_chain Stub.new(sym_or_hash, *args, &block)
          end
        end

        def playback(instance, chain_id, *args, &block)
          player          = Player.new
          player.chain    = chains.find_by_id(chain_id)
          player.instance = instance
          player.args     = args
          player.block    = block
          player.play
        end

        def verify
          if unfulfilled_expectations.any?
            raise MockExpectationError,
                  "Exactly one instance should have received the following message(s)" +
                  " but didn't: #{unfulfilled_expectation_names}"
          end
        end
        
        def remove_chains
          chains.each {|chain| chain.restore }
        end
        
      private

        def unfulfilled_expectation_names
          unfulfilled_expectations.map {|expectation| expectation.method_name.to_s }.sort.join(', ')
        end
        
        def unfulfilled_expectations
          chains.expectations.reject {|expectation| expectation.fulfilled? }
        end

        def add_chain(chain)
          chain.attach(@class)
          chains.add(chain)
        end

      end
      
    end
  end
end