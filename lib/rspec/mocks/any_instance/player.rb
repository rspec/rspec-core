module RSpec
  module Mocks
    module AnyInstance

      class Player
        
        attr_accessor :chain, :instance, :args, :block
        
        def play
          chain.expectation? ? playback_expectation : playback_stub
        end
          
      private
        
        def playback_stub
          chain.with_siblings.each(&playback_chain)
          invoke(chain.method_name)
        end
        
        def playback_expectation
          playable_chains.empty? ? invoke_backup : play_playable_chains
        end
        
        def play_playable_chains
          playable_chains.each(&playback_chain)
          result = invoke(chain.method_name)
          expect_once if expected_once?
          result
        end
        
        def expected_once?
          not chain.any_single_instance_messages?
        end
        
        def expect_once
          instance.instance_eval(<<-EOM, __FILE__, __LINE__)
            def #{chain.method_name}(*args, &blk)
              raise MockExpectationError,
                    "The message :#{chain.method_name} has already been received by #{chain.instance}"
            end
          EOM
        end
        
        def playable_chains
          @playable_chains ||= chain.with_siblings.unplayed.playable(args)
        end
        
        def playback_chain
          lambda do |chain|
            chain.instance = instance
            chain.playback
            chain.played = chain.fulfilled = true if chain.expectation?
          end
        end
        
        def invoke_backup
          invoke(chain.alias_method_name)
        rescue NoMethodError => ex
          raise ex.class, "undefined method `#{chain.method_name}' for #{instance}", ex.backtrace
        end
        
        def invoke(name)
          instance.send(name, *args, &block)
        end
        
      end
    
    end
  end
end