module RSpec
  module Mocks
    module AnyInstance
      class Chain
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

        def playback!(instance)
          messages.inject(instance) do |_instance, message|
            _instance.__send__(*message.first, &message.last)
          end
        end

        def constrained_to_any_of?(*constraints)
          constraints.any? do |constraint|
            messages.any? do |message|
              message.first.first == constraint
            end
          end
        end

        private
        def messages
          @messages ||= []
        end

        def last_message
          messages.last.first.first unless messages.empty?
        end

        def record(rspec_method_name, *args, &block)
          verify_invocation_order(rspec_method_name, *args, &block)
          messages << [args.unshift(rspec_method_name), block]
          self
        end
      end
    end
  end
end
