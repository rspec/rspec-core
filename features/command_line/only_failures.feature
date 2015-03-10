@announce @wip
Feature: Only Failures

  Background:
    Given a file named "spec/spec_helper.rb" with:
      """ruby
      RSpec.configure do |c|
        c.example_status_persistence_file_path = "examples.txt"
      end
      """
    And a file named ".rspec" with:
      """
      --require spec_helper
      --order random
      """
    And a file named "spec/array_spec.rb" with:
      """ruby
      RSpec.describe 'Arrays' do
        specify { expect([1, 2]).to include(1) }
        specify { expect([1, 2]).to include(3) } # failure
        specify { expect([1, 2]).to include(2) }
      end
      """
    And a file named "spec/string_spec.rb" with:
      """ruby
      RSpec.describe 'Strings' do
        specify { expect('a').to eq('a') }
        specify { expect('a').to eq('b') } # failure
        specify { expect('c').to eq('c') }
        specify { expect('c').to eq('b') } # failure
      end
      """
    And I have run `rspec` once, resulting in "7 examples, 3 failures"

  Scenario: Just `--only-failures`
    When I run `rspec --only-failures`
    Then the output should contain "3 examples, 3 failures"

  Scenario: Combining `--only-failures` with a file name
    When I run `rspec spec/array_spec.rb --only-failures`
    Then the output should contain "1 example, 1 failure"
    When I run `rspec spec/string_spec.rb --only-failures`
    Then the output should contain "2 examples, 2 failures"

  Scenario: Using `--next-failure`
    When I run `rspec --next-failure`
    Then the output should contain "adf"

