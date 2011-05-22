module RSpec
  module Mocks
    module AnyInstance

      class Message < Struct.new(:name, :args, :block)
        def unplayable?(arguments)
          name == :with && args != arguments
        end
      end
    
    end
  end
end