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
        end

        private
        def verify_invocation_order(rspec_method_name, args, block)
        end
      end

      class Recorder
        def initialize(klass)
          @observed_methods = {}
          @played_methods = []
          @klass = klass
        end

        def stub(method_name, *args, &block)
          observe!(method_name)
          @observed_methods[method_name.to_sym] = StubChain.new(method_name, *args, &block)
        end

        def should_receive(method_name, *args, &block)
          observe!(method_name)
          @observed_methods[method_name.to_sym] = ExpectationChain.new(method_name, *args, &block)
        end

        def stop_observing_currently_observed_methods!
          observed_method_names.each do |method_name|
            stop_observing!(method_name)
          end
        end

        def playback_to_uninvoked_observed_methods_with_expectations!(instance)
          @observed_methods.each do |method_name, chain|
            case chain
            when ExpectationChain
              chain.playback!(instance) unless @played_methods.include?(method_name)
            end
          end
        end

        def playback!(instance, method_name)
          RSpec::Mocks::space.add(instance) if RSpec::Mocks::space
          @observed_methods[method_name].playback!(instance)
          @played_methods << method_name
        end

        private
        def observed_method_names
          @observed_methods.keys
        end

        def build_alias_method_name(method_name)
          "__#{method_name}_without_any_instance__".to_sym
        end

        def stop_observing!(method_name)
          if @klass.instance_methods.include?(build_alias_method_name(method_name))
            restore_original_method!(method_name)
          else
            remove_dummy_method!(method_name)
          end
          @observed_methods.delete(method_name)
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

        def observe!(method_name)
          alias_method_name = build_alias_method_name(method_name)
          @klass.class_eval do
            if instance_methods.include?(method_name)
              alias_method alias_method_name, method_name
            end
          end
          method = <<-EOM
            def #{method_name}(*args, &blk)
              self.class.__recorder.playback!(self, :#{method_name})
              self.send(:#{method_name}, *args, &blk)
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
        super
      ensure
        rspec_reset
      end

      def rspec_reset
        __recorder.stop_observing_currently_observed_methods!
        @__recorder = nil
        response = super
        response
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
