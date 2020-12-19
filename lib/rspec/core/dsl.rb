module RSpec
  module Core
    # DSL defines methods to group examples, most notably `describe`,
    # and exposes them as class methods of {RSpec}.
    #
    # By default the methods `describe`, `context` and `example_group`
    # are exposed. These methods define a named context for one or
    # more examples. The given block is evaluated in the context of
    # a generated subclass of {RSpec::Core::ExampleGroup}.
    #
    # ## Examples:
    #
    #     RSpec.describe "something" do
    #       context "when something is a certain way" do
    #         it "does something" do
    #           # example code goes here
    #         end
    #       end
    #     end
    #
    # @see ExampleGroup
    # @see ExampleGroup.example_group
    module DSL
      # @private
      def self.example_group_aliases
        @example_group_aliases ||= []
      end

      # @private
      def self.expose_example_group_alias(name)
        return if example_group_aliases.include?(name)

        example_group_aliases << name

        (class << RSpec; self; end).__send__(:define_method, name) do |*args, &example_group_block|
          group = RSpec::Core::ExampleGroup.__send__(name, *args, &example_group_block)
          RSpec.world.record(group)
          group
        end
      end

      class << self
        # @private
        attr_accessor :top_level
      end
    end
  end
end

# Capture main without an eval.
::RSpec::Core::DSL.top_level = self
