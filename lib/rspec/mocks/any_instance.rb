module RSpec
  module Mocks
    module AnyInstance
      class Chain
        def initialize(rspec_method_name, method_name, *args, &block)
          @messages = []
          record(rspec_method_name, [method_name] + args, block)
        end

        [
          :with, :and_return, :and_raise, :and_yield,
          :once, :twice, :any_number_of_times,
          :exactly, :times, :never,
          :at_least, :at_most
          ].each do |method_name|
            dispatch_method_definition = <<-EOM
              def #{method_name}(*args, &block)
                record(:#{method_name}, args, block)
              end
            EOM
          class_eval(dispatch_method_definition, __FILE__, __LINE__)
        end

        def playback!(instance)
          @messages.inject(instance) do |instance, message|
            instance.__send__(*message.first, &message.last)
          end
        end

        def received_rspec_method?(rspec_method_name)
          !!@messages.find do |message|
            message.first.first == rspec_method_name
          end
        end
        
        def expectation_fulfilled_at_least_once?
          # implement in subclasses
          raise NotImplementedError
        end
        
        private
        def verify_invocation_order(rspec_method_name, args, block)
          # implement in subclasses
          raise NotImplementedError
        end

        def last_message
          @messages.last.first.first unless @messages.empty?
        end

        def record(rspec_method_name, args, block)
          verify_invocation_order(rspec_method_name, args, block)
          @messages << [args.unshift(rspec_method_name), block]
          self
        end
      end

      class StubChain < Chain
        def invocation_order
          @invocation_order ||= {
            :stub => [nil],
            :with => [:stub],
            :and_return => [:with, :stub],
            :and_raise => [:with, :stub],
            :and_yield => [:with, :stub]
          }
        end

        def initialize(*args, &block)
          super(:stub, *args, &block)
        end

        def expectation_fulfilled_at_least_once?
          true
        end

        private
        def verify_invocation_order(rspec_method_name, args, block)
          if !invocation_order[rspec_method_name].include?(last_message)
            raise(NoMethodError, "Undefined method #{rspec_method_name}")
          end
        end
      end

      class ExpectationChain < Chain
        def invocation_order
          @invocation_order ||= {
            :should_receive => [nil],
            :with => [:should_receive],
            :and_return => [:with, :should_receive],
            :and_raise => [:with, :should_receive]
          }
        end

        def initialize(*args, &block)
          super(:should_receive, *args, &block)
          @expectation_fulfilled = false
        end

        def expectation_fulfilled!
          @expectation_fulfilled = true
        end
        
        def expectation_fulfilled_at_least_once?
          (received_rspec_method?(:never) || received_rspec_method?(:any_number_of_times)) || @expectation_fulfilled
        end
        
        private
        def verify_invocation_order(rspec_method_name, args, block)
        end
      end

      class Recorder
        def initialize(klass)
          @message_chains = {}
          @observed_methods = []
          @played_methods = {}
          @klass = klass
          @expectation_set = false
          @expectation_fulfilled = false
        end

        def stub(method_name, *args, &block)
          method_name_symbol = method_name.to_sym
          observe!(method_name_symbol)
          @message_chains[method_name_symbol] = StubChain.new(method_name_symbol, *args, &block)
        end

        def should_receive(method_name, *args, &block)
          method_name_symbol = method_name.to_sym
          observe!(method_name_symbol)
          @expectation_set = true
          @message_chains[method_name_symbol] = ExpectationChain.new(method_name, *args, &block)
        end

        def stop_observing_currently_observed_methods!
          @observed_methods.each do |method_name|
            restore_method!(method_name)
          end
        end

        def playback!(instance, method_name)
          RSpec::Mocks::space.add(instance) if RSpec::Mocks::space
          @message_chains[method_name].playback!(instance)
          @played_methods[method_name] = instance
          received_message_for_a_method_with_an_expectation!(method_name) if has_expectation?(method_name)
        end

        def instance_that_received(method_name)
          @played_methods[method_name]
        end
        
        def verify
          if @expectation_set && !each_expectation_fulfilled_at_least_once?
            raise RSpec::Mocks::MockExpectationError, "Exactly one instance should have received the following message(s) but didn't: #{methods_with_uninvoked_expectations.sort.join(', ')}"
          end
        end
        
        private
        def each_expectation_fulfilled_at_least_once?
          !@message_chains.find do |method_name, chain|
            not chain.expectation_fulfilled_at_least_once?
          end
        end
        
        def has_expectation?(method_name)
          @message_chains[method_name].is_a?(ExpectationChain)
        end
        
        def methods_with_uninvoked_expectations
          @message_chains.map{|method_name, chain| method_name.to_s if chain.is_a?(ExpectationChain) && !chain.expectation_fulfilled_at_least_once? }.compact
        end
        
        def received_message_for_a_method_with_an_expectation!(method_name)
          @message_chains[method_name].expectation_fulfilled!
          @expectation_fulfilled = true
          restore_method!(method_name)
          mark_invoked!(method_name)
        end
        
        def restore_method!(method_name)
          if @klass.method_defined?(build_alias_method_name(method_name))
            restore_original_method!(method_name)
          else
            remove_dummy_method!(method_name)
          end
        end
        
        def build_alias_method_name(method_name)
          "__#{method_name}_without_any_instance__".to_sym
        end

        def restore_original_method!(method_name)
          alias_method_name = build_alias_method_name(method_name)
          @klass.class_eval do
            alias_method  method_name, alias_method_name
            remove_method alias_method_name
          end
        end

        def remove_dummy_method!(method_name)
          @klass.class_eval do
            remove_method method_name
          end
        end

        def backup_method!(method_name)
          alias_method_name = build_alias_method_name(method_name)
          @klass.class_eval do
            if method_defined?(method_name)
              alias_method alias_method_name, method_name
            end
          end
        end
        
        def observe!(method_name)
          @observed_methods << method_name
          backup_method!(method_name)
          method = <<-EOM
            def #{method_name}(*args, &blk)
              self.class.__recorder.playback!(self, :#{method_name})
              self.send(:#{method_name}, *args, &blk)
            end
          EOM
          @klass.class_eval(method, __FILE__, __LINE__)
        end

        def mark_invoked!(method_name)
          backup_method!(method_name)
          method = <<-EOM
            def #{method_name}(*args, &blk)
              method_name = :#{method_name}
              current_instance = self
              invoked_instance = self.class.__recorder.instance_that_received(method_name)
              raise RSpec::Mocks::MockExpectationError, "The message '#{method_name}' was received by \#{self.inspect} but has already been received by \#{invoked_instance}"
            end
          EOM
          @klass.class_eval(method, __FILE__, __LINE__)
        end
      end

      def any_instance
        RSpec::Mocks::space.add(self) if RSpec::Mocks::space
        __recorder
      end

      def rspec_verify
        value = super
        __recorder.verify
        value
      ensure
        rspec_reset
      end

      def rspec_reset
        __recorder.stop_observing_currently_observed_methods!
        @__recorder = nil
        super
      end

      def reset?
        !@__recorder && super
      end

      def __recorder
        @__recorder ||= AnyInstance::Recorder.new(self)
      end
    end
  end
end
