Feature: `--fail-fast` option

  Use the `--fail-fast` option to tell RSpec to stop running the test suite on
  the first failed test.  `--fast-fail` is also valid for our forgetful or
  dyslexic friends.

  You may also specify `--no-fail-fast` to turn it off (default behaviour).
  Also available as `--no-fast-fail`.

  Background:
    Given a file named "fail_fast_spec.rb" with:
      """ruby
      RSpec.describe "fail fast" do
        it "passing test" do; end
        it "failing test" do
          fail
        end
        it "this should not be run" do; end
      end
      """

  Scenario: Using `--fail-fast`
    When I run `rspec . --fail-fast`
    Then the output should contain ".F"
    Then the output should not contain ".F."

  Scenario: Using `--no-fail-fast`
    When I run `rspec . --no-fail-fast`
    Then the output should contain ".F."

  Scenario: Using `--fast-fail`
    When I run `rspec . --fast-fail`
    Then the output should contain ".F"
    Then the output should not contain ".F."

  Scenario: Using `--no-fast-fail`
    When I run `rspec . --no-fast-fail`
    Then the output should contain ".F."
