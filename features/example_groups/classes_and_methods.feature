Feature: define example groups with classes and methods

  You can use familiar constructs like Ruby classes and methods if you prefer
  them over the `describe`/`it` DSL.

  Scenario: declare example group by subclassing RSpec::ExampleGroup
    Given a file named "array_spec.rb" with:
      """
      class ArrayTest < RSpec::TestCase
        def test_is_empty_when_created
          assert Array.new.empty?
        end
      end
      """
    When I run `rspec array_spec.rb --format doc`
    Then the output should contain:
      """
      Array
        is_empty_when_created
      """
    And the examples should all pass

