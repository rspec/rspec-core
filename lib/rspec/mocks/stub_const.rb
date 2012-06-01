module RSpec
  module Mocks
    module RecursiveConstMethods
      def recursive_const_get(name)
        name.split('::').inject(Object) { |mod, name| mod.const_get name }
      end

      def recursive_const_defined?(name)
        name.split('::').inject(Object) do |mod, name|
          return false unless mod.const_defined?(name)
          mod.const_get name
        end
      end
    end

    class ConstantStubber
      extend RecursiveConstMethods

      class DefinedConstantReplacer
        include RecursiveConstMethods
        attr_reader :original_value, :full_constant_name

        def initialize(full_constant_name, stubbed_value, transfer_nested_constants)
          @full_constant_name        = full_constant_name
          @stubbed_value             = stubbed_value
          @transfer_nested_constants = transfer_nested_constants
        end

        def stub!
          context_parts = @full_constant_name.split('::')
          @const_name = context_parts.pop
          @context = recursive_const_get(context_parts.join('::'))
          @original_value = @context.const_get(@const_name)

          constants_to_transfer = verify_constants_to_transfer!

          @context.send(:remove_const, @const_name)
          @context.const_set(@const_name, @stubbed_value)

          transfer_nested_constants(constants_to_transfer)
        end

        def rspec_reset
          if recursive_const_get(@full_constant_name).equal?(@stubbed_value)
            @context.send(:remove_const, @const_name)
            @context.const_set(@const_name, @original_value)
          end
        end

        def transfer_nested_constants(constants)
          constants.each do |const|
            @stubbed_value.const_set(const, original_value.const_get(const))
          end
        end

        def verify_constants_to_transfer!
          return [] unless @transfer_nested_constants

          { @original_value => "the original value", @stubbed_value => "the stubbed value" }.each do |value, description|
            unless value.respond_to?(:constants)
              raise ArgumentError,
                "Cannot transfer nested constants for #{@full_constant_name} " +
                "since #{description} is not a class or module and only classes " +
                "and modules support nested constants."
            end
          end

          if @transfer_nested_constants.is_a?(Array)
            @transfer_nested_constants = @transfer_nested_constants.map(&:to_s) if RUBY_VERSION == '1.8.7'
            undefined_constants = @transfer_nested_constants - @original_value.constants

            if undefined_constants.any?
              available_constants = @original_value.constants - @transfer_nested_constants
              raise ArgumentError,
                "Cannot transfer nested constant(s) #{undefined_constants.join(' and ')} " +
                "for #{@full_constant_name} since they are not defined. Did you mean " +
                "#{available_constants.join(' or ')}?"
            end

            @transfer_nested_constants
          else
            @original_value.constants
          end
        end
      end

      class UndefinedConstantSetter
        include RecursiveConstMethods

        attr_reader :full_constant_name

        def initialize(full_constant_name, stubbed_value)
          @full_constant_name = full_constant_name
          @stubbed_value      = stubbed_value
        end

        def original_value
          # always nil
        end

        def stub!
          context_parts = @full_constant_name.split('::')
          const_name = context_parts.pop

          remaining_parts = context_parts.dup
          @deepest_defined_const = context_parts.inject(Object) do |klass, name|
            break klass unless klass.const_defined?(name)
            remaining_parts.shift
            klass.const_get(name)
          end

          context = remaining_parts.inject(@deepest_defined_const) do |klass, name|
            klass.const_set(name, Module.new)
          end

          @const_to_remove = remaining_parts.first || const_name
          context.const_set(const_name, @stubbed_value)
        end

        def rspec_reset
          if recursive_const_get(@full_constant_name).equal?(@stubbed_value)
            @deepest_defined_const.send(:remove_const, @const_to_remove)
          end
        end
      end

      def self.stub!(constant_name, value, options = {})
        stubber = if recursive_const_defined?(constant_name)
          DefinedConstantReplacer.new(constant_name, value, options[:transfer_nested_constants])
        else
          UndefinedConstantSetter.new(constant_name, value)
        end

        stubbers << stubber

        stubber.stub!
        ensure_registered_with_rspec_mocks
        stubber.original_value
      end

      def self.ensure_registered_with_rspec_mocks
        return if @registered_with_rspec_mocks
        ::RSpec::Mocks.space.add(self)
        @registered_with_rspec_mocks = true
      end

      def self.rspec_reset
        @registered_with_rspec_mocks = false

        # We use reverse order so that if the same constant
        # was stubbed multiple times, the original value gets
        # properly restored.
        stubbers.reverse.each { |s| s.rspec_reset }

        stubbers.clear
      end

      def self.stubbers
        @stubbers ||= []
      end

      def self.find_original_value_for(constant_name)
        stubber = stubbers.find { |s| s.full_constant_name == constant_name }
        yield stubber.original_value if stubber
        self
      end
    end
  end
end

