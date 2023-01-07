Feature: Pending failure output

  Configure the format of pending examples output with an option (defaults to `:full`):

  ```ruby
  RSpec.configure do |c|
    c.pending_failure_output = :no_backtrace
  end
  ```

  Allowed options are `:full`, `:no_backtrace` and `:skip`.

  Background:
    Given a file named "spec/example_spec.rb" with:
      """ruby
      require "spec_helper"

      RSpec.describe "something" do
        pending "will never happen again" do
          expect(Time.now.year).to eq(2021)
        end
      end
      """

  Scenario: By default outputs backtrace and details
    Given a file named "spec/spec_helper.rb" with:
      """ruby
      """
    When I run `rspec spec`
    Then the examples should all pass
    And the output should contain "Pending: (Failures listed here are expected and do not affect your suite's status)"
    And the output should contain "1) something will never happen again"
    And the output should contain "expected: 2021"
    And the output should contain "./spec/example_spec.rb:5"

  Scenario: Setting `pending_failure_output` to `:no_backtrace` hides the backtrace
    Given a file named "spec/spec_helper.rb" with:
      """ruby
      RSpec.configure { |c| c.pending_failure_output = :no_backtrace }
      """
    When I run `rspec spec`
    Then the examples should all pass
    And the output should contain "Pending: (Failures listed here are expected and do not affect your suite's status)"
    And the output should contain "1) something will never happen again"
    And the output should contain "expected: 2021"
    And the output should not contain "./spec/example_spec.rb:5"

  Scenario: Setting `pending_failure_output` to `:skip` hides the backtrace
    Given a file named "spec/spec_helper.rb" with:
      """ruby
      RSpec.configure { |c| c.pending_failure_output = :skip }
      """
    When I run `rspec spec`
    Then the examples should all pass
    And the output should not contain "Pending: (Failures listed here are expected and do not affect your suite's status)"
    And the output should not contain "1) something will never happen again"
    And the output should not contain "expected: 2021"
    And the output should not contain "./spec/example_spec.rb:5"
