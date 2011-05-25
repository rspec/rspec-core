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
          chain { reject {|chain| chain.played? } }
        end
        
        def expectations
          chain { select {|chain| chain.is_a?(Expectation) } }
        end
        
        def find_with_siblings(chain)
          chain { select {|c| c.method_name == chain.method_name } }
        end
        
        def has_playable_messages(args)
          chain { reject {|chain| chain.any_unplayable_messages?(args) } }
        end
        
      private
        
        def chain
          self.class.new yield
        end

      end
      
    end
  end
end