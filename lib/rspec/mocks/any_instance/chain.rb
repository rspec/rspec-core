module RSpec
  module Mocks
    module AnyInstance
      
      class Chain
        
        InvocationOrder = {
          :stub => [nil],
          :should_receive => [nil],
          :with => [:stub, :should_receive],
          :and_return => [:with, :stub, :should_receive],
          :and_raise => [:with, :stub, :should_receive],
          :and_yield => [:with, :stub]
        }
        
        attr_accessor :recorded_class, :instance, :dummy
        
        [ :with, :and_return, :and_raise, :and_yield,
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
          messages.inject(instance) {|i, message| message.invoke(i) }
        end
        
        def attach(cls)
          self.recorded_class = cls
          backup unless backed_up?
          hijack
        end
        
        def backup
          recorded_class_eval <<-RUBY
            if method_defined?(:#{method_name})
              alias_method :#{alias_method_name}, :#{method_name}
            else
              #{dummy!}
            end
          RUBY
        end
        
        def restore_original
          recorded_class_eval <<-RUBY
            alias_method :#{method_name}, :#{alias_method_name}
            remove_method :#{alias_method_name}
          RUBY
        end
        
        def hijack
          recorded_class_eval <<-RUBY
            def #{method_name}(*args, &blk)
              Mocks.space.add(self)
              self.class.__recorder.playback(self, #{object_id}, *args, &blk)
            end
          RUBY
        end
        
        def backed_up?
          recorded_class.method_defined?(alias_method_name)
        end
        
        def restore
          backed_up? ? restore_original : remove if dummy?
        end
        
        def remove
          recorded_class_eval "remove_method(:#{method_name})"
        end
        
        def expectation?
          is_a?(Expectation)
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

        def record(method_name, *args, &block)
          verify_invocation_order(method_name, *args, &block)
          add_message(method_name, *args, &block)
          self
        end
        
        def verify_invocation_order(rspec_method_name, *args, &block)
          if invocation_order = InvocationOrder[rspec_method_name]
            unless invocation_order.include?(last_message)
              raise NoMethodError, "Undefined method #{rspec_method_name}"
            end
          end
        end
        
        def recorded_class_eval(code)
          recorded_class.class_eval(code, __FILE__, __LINE__)
        end
        
        def with_siblings
          recorded_class.__recorder.chains.find_with_siblings(self)
        end
        
        def add_message(method_name, *args, &block)
          messages.push Message.new(method_name, args, block)
        end
        
        def last_message
          messages.last.name unless messages.empty?
        end
        
        def messages
          @messages ||= []
        end
        
      end
    
    end
  end
end