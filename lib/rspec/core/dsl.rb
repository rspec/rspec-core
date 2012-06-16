module RSpec
  module Core
    # Adds the `describe` method to the top-level namespace.
    module DSL
      # Generates a subclass of {ExampleGroup}
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
      # @see ExampleGroup.describe
      def describe(*args, &example_group_block)
        RSpec::Core::ExampleGroup.describe(*args, &example_group_block).register
      end
    end
  end
end

# make describe available on the main object, but not all objects
extend RSpec::Core::DSL

# make describe available on modules so example groups
# can be nested within them.
Module.send(:include, RSpec::Core::DSL)
