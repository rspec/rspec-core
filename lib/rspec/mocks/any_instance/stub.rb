module RSpec
  module Mocks
    module AnyInstance

      class Stub < Chain        
        
        def initialize(*args, &block)
          record(:stub, *args, &block)
        end
        
      end
    
    end
  end
end