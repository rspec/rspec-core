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
          @messages.find do |message|
            message.first.first == rspec_method_name
          end
        end
        
        def expectation_fulfilled_at_least_once
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

        def expectation_fulfilled_at_least_once
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
          @expectation_fulfilled = true unless (received_rspec_method?(:never) || received_rspec_method?(:any_number_of_times))
        end
        
        def expectation_fulfilled_at_least_once
          @expectation_fulfilled
        end
        
        private
        def verify_invocation_order(rspec_method_name, args, block)
        end
      end

      class Recorder
        def initialize(klass)
          @observed_methods = {}
          @played_methods = {}
          @klass = klass
          @expectation_set = false
          @expectation_fulfilled = false
        end

        def stub(method_name, *args, &block)
          observe!(method_name)
          @observed_methods[method_name.to_sym] = StubChain.new(method_name, *args, &block)
        end

        def should_receive(method_name, *args, &block)
          observe!(method_name)
          @expectation_set = true
          @observed_methods[method_name.to_sym] = ExpectationChain.new(method_name, *args, &block)
        end

        def stop_observing_currently_observed_methods!
          observed_method_names.each do |method_name|
            restore_method!(method_name)
          end
        end

        def playback_to_uninvoked_observed_methods_with_expectations!(instance)
          @observed_methods.each do |method_name, chain|
            case chain
            when ExpectationChain
              chain.playback!(instance) unless @played_methods[method_name]
            end
          end
        end

        def playback!(instance, method_name)
          RSpec::Mocks::space.add(instance) if RSpec::Mocks::space
          @observed_methods[method_name].playback!(instance)
          @played_methods[method_name] = instance
          received_message_for_a_method_with_an_expectation!(method_name) if has_expectation?(method_name)
        end

        def instance_that_received(method_name)
          @played_methods[method_name]
        end
        
        def verify
          if @expectation_set && !each_expectation_fulfilled_at_least_once?
            raise RSpec::Mocks::MockExpectationError, "Exactly one instance should have received the following message(s) but didn't: #{methods_with_expectations.join(', ')}"
          end
        end
        
        private
        def each_expectation_fulfilled_at_least_once?
          # @observed_methods.detect do |method_name, chain|
          #   chain.expectation_fulfilled? == false
          # end
          @expectation_fulfilled
        end
        
        def has_expectation?(method_name)
          @observed_methods[method_name].is_a?(ExpectationChain)
        end
        
        def methods_with_expectations
          @observed_methods.map{|method_name, chain| method_name if chain.is_a?(ExpectationChain)}.compact
        end
        
        def received_message_for_a_method_with_an_expectation!(method_name)
          @observed_methods[method_name].expectation_fulfilled!
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
          @observed_methods.delete(method_name)
        end
        
        def observed_method_names
          @observed_methods.keys
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

      module ExpectationEnsurer
        def rspec_verify
          self.class.__recorder.playback_to_uninvoked_observed_methods_with_expectations!(self)
          super
        end
      end

      def any_instance
        RSpec::Mocks::space.add(self) if RSpec::Mocks::space
        self.class_eval{ include ExpectationEnsurer }
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
