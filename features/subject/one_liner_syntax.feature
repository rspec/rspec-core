Feature: One-liner syntax

  RSpec supports a one-liner syntax, `is_expected`, for setting an expectation
  on the `subject`. RSpec will give the examples a doc string that is auto-
  generated from the matcher used in the example. This is designed specifically
  to help avoid duplication in situations where the doc string and the matcher
  used in the example mirror each other exactly. When used excessively, it can
  produce documentation output that does not read well or contribute to
  understanding the object you are describing. This syntax is a shorthand for
  `expect(subject)`.

  Notes:

    * This feature is only available when using rspec-expectations.
    * Examples defined using this one-liner syntax cannot be directly selected from the command line using the [`--example` option](../command-line/example-option).
    * The one-liner syntax only works with non-block expectations (e.g. `expect(obj).to eq`, etc) and it cannot be used with block expectations (e.g. `expect { object }`).

  Scenario: Implicit subject
    Given a file named "example_spec.rb" with:
      """ruby
      RSpec.describe Array do
        describe "when first created" do
          it { is_expected.to be_empty }
        end
      end
      """
    When I run `rspec example_spec.rb --format doc`
    Then the examples should all pass
     And the output should contain:
       """
       Array
         when first created
           is expected to be empty
       """

  Scenario: Explicit subject
    Given a file named "example_spec.rb" with:
      """ruby
      RSpec.describe Array do
        describe "with 3 items" do
          subject { [1,2,3] }
          it { is_expected.not_to be_empty }
        end
      end
      """
    When I run `rspec example_spec.rb --format doc`
    Then the examples should all pass
     And the output should contain:
       """
       Array
         with 3 items
           is expected not to be empty
       """
