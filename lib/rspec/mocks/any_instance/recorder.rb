module RSpec
  module Mocks
    module AnyInstance
      class Recorder
        attr_reader :message_chains
        def initialize(klass)
          @message_chains = MessageChains.new
          @observed_methods = []
          @played_methods = {}
          @klass = klass
          @expectation_set = false
        end
        
        def unstub(method_name)
          unless @observed_methods.include?(method_name.to_sym)
            raise RSpec::Mocks::MockExpectationError, "The method `#{method_name}` was not stubbed or was already unstubbed"
          end
          message_chains.remove_stub_chains_for!(method_name)
          stop_observing!(method_name) unless message_chains.has_expectation?(method_name)
        end
        
        def stub(method_name_or_method_map, *args, &block)
          if method_name_or_method_map.is_a?(Hash)
            method_map = method_name_or_method_map
            method_map.each do |method_name, return_value| 
              observe!(method_name)
              message_chains.add(method_name, chain = StubChain.new(method_name))
              chain.and_return(return_value)
            end
            method_map
          else
            method_name = method_name_or_method_map
            observe!(method_name)
            message_chains.add(method_name, chain = StubChain.new(method_name, *args, &block))
            chain
          end
        end

        def stub!(*)
          raise "stub! is not supported on any_instance. Use stub instead."
        end

        def stub_chain(method_name_or_string_chain, *args, &block)
          if period_separated_method_chain?(method_name_or_string_chain)
            first_method_name = method_name_or_string_chain.split('.').first.to_sym
          else
            first_method_name = method_name_or_string_chain
          end
          observe!(first_method_name)
          message_chains.add(first_method_name, chain = StubChainChain.new(method_name_or_string_chain, *args, &block))
          chain
        end
        
        def should_receive(method_name, *args, &block)
          observe!(method_name)
          @expectation_set = true
          message_chains.add(method_name, chain = ExpectationChain.new(method_name, *args, &block))
          chain
        end

        def stop_all_observation!
          @observed_methods.each do |method_name|
            restore_method!(method_name)
          end
        end

        def playback!(instance, method_name)
          RSpec::Mocks::space.add(instance)
          message_chains.playback!(instance, method_name)
          @played_methods[method_name] = instance
          received_expected_message!(method_name) if message_chains.has_expectation?(method_name)
        end

        def instance_that_received(method_name)
          @played_methods[method_name]
        end

        def verify
          if @expectation_set && !message_chains.each_expectation_fulfilled?
            raise RSpec::Mocks::MockExpectationError, "Exactly one instance should have received the following message(s) but didn't: #{message_chains.unfulfilled_expectations.sort.join(', ')}"
          end
        end

        private
        def period_separated_method_chain?(method_name)
          method_name.is_a?(String) && method_name.include?('.')
        end
        
        def received_expected_message!(method_name)
          message_chains.received_expected_message!(method_name)
          restore_method!(method_name)
          mark_invoked!(method_name)
        end
        
        def restore_method!(method_name)
          if public_protected_or_private_method_defined?(build_alias_method_name(method_name))
            restore_original_method!(method_name)
          else
            remove_dummy_method!(method_name)
          end
        end

        def build_alias_method_name(method_name)
          "__#{method_name}_without_any_instance__"
        end

        def restore_original_method!(method_name)
          alias_method_name = build_alias_method_name(method_name)
          @klass.class_eval do
            remove_method method_name
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
            alias_method alias_method_name, method_name
          end if public_protected_or_private_method_defined?(method_name)
        end
        
        def public_protected_or_private_method_defined?(method_name)
          @klass.method_defined?(method_name) || @klass.private_method_defined?(method_name)
        end
        
        def stop_observing!(method_name)
          restore_method!(method_name)
          @observed_methods.delete(method_name)
        end

        def already_observing?(method_name)
          @observed_methods.include?(method_name)
        end

        def observe!(method_name)
          stop_observing!(method_name) if already_observing?(method_name)
          @observed_methods << method_name
          backup_method!(method_name)
          @klass.class_eval(<<-EOM, __FILE__, __LINE__)
            def #{method_name}(*args, &blk)
              self.class.__recorder.playback!(self, :#{method_name})
              self.__send__(:#{method_name}, *args, &blk)
            end
          EOM
        end

        def mark_invoked!(method_name)
          backup_method!(method_name)
          @klass.class_eval(<<-EOM, __FILE__, __LINE__)
            def #{method_name}(*args, &blk)
              method_name = :#{method_name}
              current_instance = self
              invoked_instance = self.class.__recorder.instance_that_received(method_name)
              raise RSpec::Mocks::MockExpectationError, "The message '#{method_name}' was received by \#{self.inspect} but has already been received by \#{invoked_instance}"
            end
          EOM
        end
      end
    end
  end
end
