module RSpec
  module Mocks
    module AnyInstance

      class Message < Struct.new(:name, :args, :block)
        
        def invoke(instance)
          instance.send(name, *args, &block)
        end
        
        def unplayable?(arguments)
          name == :with && args != arguments
        end
        
      end
    
    end
  end
end