module RSpec
  module Core
    # Adds the `describe` method to the top-level namespace.
    module DSL
      # Generates a method that passes on the message to
      # generate a subclass of {ExampleGroup}
      #
      def self.register_example_group_alias(name)
        define_method(name) do |*args, &example_group_block|
          RSpec::Core::ExampleGroup.send(name, *args, &example_group_block).register
        end
      end

      # By default, #describe is available at the top-level
      # to generate subclasses of {ExampleGroup}
      #
      # ## Examples:
      #
      #     describe "something" do
      #       it "does something" do
      #         # example code goes here
      #       end
      #     end
      #
      # @see ExampleGroup
      # @see ExampleGroup.example_group
      register_example_group_alias(:describe)

    end
  end
end

