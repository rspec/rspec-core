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
          @chains.each {|chain| restore_method(chain) }
        end
        
      private

        def unfulfilled_expectation_names
          unfulfilled_expectations.map {|expectation| expectation.method_name.to_s }.sort.join(', ')
        end
        
        def unfulfilled_expectations
          @chains.expectations.reject {|expectation| expectation.fulfilled? }
        end
      
        def restore_method(chain)
          if @class.method_defined?(chain.alias_method_name)
            restore_original_method(chain)
          else
            remove_dummy_method(chain) if chain.dummy?
          end
        end
      
        def restore_original_method(chain)
          @class.class_eval do
            alias_method chain.method_name, chain.alias_method_name
            remove_method chain.alias_method_name
          end
        end
      
        def remove_dummy_method(chain)
          @class.class_eval { remove_method(chain.method_name) }
        end

        def add_chain(chain)
          backup_method(chain) unless method_backed_up?(chain)
          add_playback_method(chain)
          @chains.add(chain)
        end
        
        def add_playback_method(chain)
          @class.class_eval(<<-EOM, __FILE__, __LINE__)
            def #{chain.method_name}(*args, &blk)
              Mocks.space.add(self)
              self.class.__recorder.playback(self, #{chain.object_id}, *args, &blk)
            end
          EOM
        end
        
        def backup_method(chain)
          @class.class_eval do
            if method_defined?(chain.method_name)
              alias_method chain.alias_method_name, chain.method_name
            else
              chain.dummy!
            end
          end
        end
        
        def method_backed_up?(chain)
          @chains.method_names.include?(chain.method_name)
        end

      end
      
    end
  end
end