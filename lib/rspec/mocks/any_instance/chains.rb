module RSpec
  module Mocks
    module AnyInstance
      
      class Chains < Array

        def add(chain)
          push(chain)
          chain
        end
        
        def find_by_id(id)
          find {|chain| chain.object_id == id }
        end
        
        def unplayed
          chainable { reject {|chain| chain.played? } }
        end
        
        def expectations
          chainable { select {|chain| chain.is_a?(Expectation) } }
        end
        
        def find_with_siblings(chain)
          chainable { select {|c| c.method_name == chain.method_name } }
        end
        
        def playable(args)
          chainable { reject {|chain| chain.any_unplayable_messages?(args) } }
        end
        
      private
        
        def chainable
          self.class.new yield
        end

      end
      
    end
  end
end