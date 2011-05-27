module RSpec
  module Mocks
    module AnyInstance

      class Expectation < Chain
        
        attr_accessor :fulfilled, :played
        
        def initialize(*args, &block)
          record(:should_receive, *args, &block)
        end
        
        def played?
          !!played
        end

        def fulfilled?
          fulfilled || constrained?(:never, :any_number_of_times)
        end
        
        def any_unplayable_messages?(args)
          messages.any? {|message| message.unplayable?(args) }
        end
        
        def any_single_instance_messages?
          messages.any? {|message| message.single_instance? }
        end
        
      end
      
    end
  end
end