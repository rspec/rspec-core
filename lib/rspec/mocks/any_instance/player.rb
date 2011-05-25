module RSpec
  module Mocks
    module AnyInstance

      class Player
        
        MoreThanOneExpectationMethods = [
          :once, 
          :twice,
          :any_number_of_times,
          :exactly,
          :times,
          :never,
          :at_least,
          :at_most
        ]
        
        attr_accessor :chains, :chain_id, :instance, :args, :block
        
        def play
          case chain
          when Stub then stub_playback
          when Expectation then expectation_playback
          end
        end
          
      private
      
        def chain
          @chain ||= chains.find_by_id(chain_id)
        end
        
        def stub_playback
          chains.find_with_siblings(chain).each(&playback_chain)
          send_to_instance(chain.method_name)
        end
        
        def expectation_playback
          if playable_chains.empty?
            send_to_backup_method
          else
            playable_chains.each(&playback_chain)
            result = send_to_instance(chain.method_name)
            override_with_expectation_error if override_with_expectation_error?
            result
          end
        end
        
        def override_with_expectation_error?
          not chain.messages.any? {|message| MoreThanOneExpectationMethods.include? message.name }
        end
        
        def override_with_expectation_error
          instance.instance_eval(<<-EOM, __FILE__, __LINE__)
            def #{chain.method_name}(*args, &blk)
              raise MockExpectationError,
                    "The message :#{chain.method_name} has already been received by #{chain.instance}"
            end
          EOM
        end
        
        def playable_chains
          chains.find_with_siblings(chain).unplayed.has_playable_messages(args)
        end
        
        def playback_chain
          lambda do |chain|
            chain.instance = instance
            chain.playback
            if chain.expectation?
              chain.played! 
              chain.fulfilled!
            end
          end
        end
        
        def send_to_backup_method
          send_to_instance(chain.alias_method_name)
        rescue NoMethodError => exception
          raise NoMethodError, "undefined method `#{chain.method_name}' for #{instance}", exception.backtrace
        end
        
        def send_to_instance(method_name)
          instance.send(method_name, *args, &block)
        end
        
      end
    
    end
  end
end