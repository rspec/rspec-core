module RSpec
  module Mocks
    module AnyInstance

      class Expectation < Chain
        
        attr_accessor :fulfilled, :played
        
        def initialize(*args, &block)
          record(:should_receive, *args, &block)
        end

        def invocation_order
          @invocation_order ||= {
            :should_receive => [nil],
            :with => [:should_receive],
            :and_return => [:with, :should_receive],
            :and_raise => [:with, :should_receive]
          }
        end
        
        def played!
          self.played = true
        end
        
        def played?
          !!played
        end

        def fulfilled!
          self.fulfilled = true
        end

        def fulfilled?
          fulfilled || constrained?(:never, :any_number_of_times)
        end
        
        def any_unplayable_messages?(args)
          messages.any? {|message| message.unplayable?(args) }
        end

        private
        def verify_invocation_order(rspec_method_name, *args, &block)
        end
      end
      
    end
  end
end