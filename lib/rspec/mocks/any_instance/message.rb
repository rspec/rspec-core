module RSpec
  module Mocks
    module AnyInstance

      class Message < Struct.new(:name, :args, :block)
        
        SingleInstanceMethods = [
          :once, 
          :twice,
          :any_number_of_times,
          :exactly,
          :times,
          :never,
          :at_least,
          :at_most
        ]
        
        def invoke(instance)
          instance.send(name, *args, &block)
        end
        
        def unplayable?(arguments)
          name == :with && args != arguments
        end
        
        def single_instance?
          SingleInstanceMethods.include?(name)
        end
        
      end
    
    end
  end
end