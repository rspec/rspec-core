Feature: define example groups with classes and methods

  You can use familiar constructs like Ruby classes and methods if you prefer
  them over the `describe`/`it` DSL.

  To get test/unit or minitest assertions you need to configure RSpec as shown
  in the following scenario:

  Scenario: declare example group by subclassing RSpec::ExampleGroup
    Given a file named "array_spec.rb" with:
      """
      RSpec.configure {|c| c.expect_with :stdlib}

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

