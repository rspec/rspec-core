Feature: aliasing
  `describe` and `context` are the default aliases for `example_group`.
  `describe` is defined at the top level, i.e. on the main Object.
  `context` is only available from within an example group, i.e. within
  a describe block.  You can describe your own aliases for `example_group`
  and give those custom aliases default meta data.

  You can also make these aliases available at the top-level of your
  specs, just add :toplevel_alias as an option.

  By default, top level aliases are included in the main- and the
  Module-namespace. This can be avoided by running with the option
  `--toplevel-off`.

  Scenario: custom example group aliases with metadata
    Given a file named "nested_example_group_aliases_spec.rb" with:
    """ruby
    RSpec.configure do |c|
      c.alias_example_group_to :detail, detailed: true, focused: false
    end

    describe "a thing" do
      describe "in broad strokes" do
        it "can do things" do
        end
      end

      detail "something less important" do
        it "can do an unimportant thing" do
        end
      end
    end
    """
    When I run `rspec nested_example_group_aliases_spec.rb --tag detailed -fdoc`
    Then the output should contain:
    """
    a thing
      something less important
    """

  Scenario: custom example group alias at the top-level
    Given a file named "top_level_example_group_aliases_spec.rb" with:
    """ruby
    RSpec.configure do |c|
      c.alias_example_group_to :detail, :toplevel_alias
    end

    detail "a thing" do
      it "works" do
      end
    end
    """
    When I run `rspec top_level_example_group_aliases_spec.rb -fdoc`
    Then the output should contain:
    """
    a thing
      works
    """

  Scenario: Turn off toplevel methods
    Given a file named "top_level_example_group_aliases_spec.rb" with:
    """ruby
    describe "is not available" do
    end
    """
    When I run `rspec --toplevel-off top_level_example_group_aliases_spec.rb -fdoc`
    Then the output should contain:
    """
    undefined method `describe'
    """

