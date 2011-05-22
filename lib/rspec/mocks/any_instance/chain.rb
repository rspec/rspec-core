module RSpec
  module Mocks
    module AnyInstance
      
      class Chain
        
        attr_accessor :instance, :dummy
        
        [
          :with, :and_return, :and_raise, :and_yield,
          :once, :twice, :any_number_of_times,
          :exactly, :times, :never,
          :at_least, :at_most
          ].each do |method_name|
            class_eval(<<-EOM, __FILE__, __LINE__)
              def #{method_name}(*args, &block)
                record(:#{method_name}, *args, &block)
              end
            EOM
        end

        def playback
          messages.inject(instance) do |instance, message|
            instance.send(message.name, *message.args, &message.block)
          end
        end
        
        def dummy!
          self.dummy = true
        end
        
        def dummy?
          !!dummy
        end
        
        def method_name
          messages.first.args.first
        end
        
        def alias_method_name
          "__#{method_name}_without_any_instance__"
        end

        def constrained?(*constraints)
          constraints.any? do |constraint|
            messages.any? {|message| message.name == constraint }
          end
        end

        def messages
          @messages ||= []
        end

        def last_message
          messages.last.name unless messages.empty?
        end

        def record(method_name, *args, &block)
          verify_invocation_order(method_name, *args, &block)
          messages << Message.new(method_name, args, block)
          self
        end
      end
    
    end
  end
end