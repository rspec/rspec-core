Feature: Using the `--only-pending` option

  The `--only-pending` option filters what examples are run so that only those that failed the last time they ran are executed. To use this option, you first have to configure `config.example_status_persistence_file_path`, which RSpec will use to store the status of each example the last time it ran.

  Either of these options can be combined with another a directory or file name; RSpec will run just the failures from the set of loaded examples.

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
      --format documentation
      """
    And a file named "spec/array_spec.rb" with:
      """ruby
      RSpec.describe 'Array' do
        it "checks for inclusion of 1" do
          expect([1, 2]).to include(1)
        end

        it "checks for inclusion of 2", skip: "just not ready for this yet..." do
          expect([1, 2]).to include(2)
        end

        it "checks for inclusion of 3" do
          expect([1, 2]).to include(3) # failure
        end
      end
      """
    And a file named "spec/string_spec.rb" with:
      """ruby
      RSpec.describe 'String' do
        it "checks for inclusion of 'foo'" do
          expect("food").to include('foo')
        end

        it "checks for inclusion of 'bar'" do
          expect("food").to include('bar') # failure
        end

        it "checks for inclusion of 'baz'" do
          expect("bazzy").to include('baz')
        end

        it "checks for inclusion of 'foobar'" do
          expect("food").to include('foobar') # failure
        end

        it "checks for inclusion of 'sum'", skip: "just not ready for this yet..." do
          expect("lorem ipsum").to include('sum')
        end

        it "checks for inclusion of 'sit'", skip: "...nor am I ready for this..." do
          expect("dolor sit").to include('sit')
        end
      end
      """
    And a file named "spec/passing_spec.rb" with:
      """ruby
      puts "Loading passing_spec.rb"

      RSpec.describe "A passing spec" do
        it "passes" do
          expect(1).to eq(1)
        end
      end
      """
    And I have run `rspec` once, resulting in "10 examples, 3 failures, 3 pending"

  Scenario: Running `rspec --only-pending` loads only spec files with failures and runs only the failures
    When I run `rspec --only-pending`
    Then the output from "rspec --only-pending" should contain "3 examples, 0 failures, 3 pending"
     And the output from "rspec --only-pending" should not contain "Loading passing_spec.rb"

  Scenario: Combine `--only-pending` with a file name
    When I run `rspec spec/array_spec.rb --only-pending`
    Then the output should contain "1 example, 0 failures, 1 pending"
    When I run `rspec spec/string_spec.rb --only-pending`
    Then the output should contain "2 examples, 0 failures, 2 pending"

  Scenario: Running `rspec --only-pending` with spec files that pass doesn't run anything
    When I run `rspec spec/passing_spec.rb --only-pending`
    Then it should pass with "0 examples, 0 failures"

  Scenario: Clear error given when using `--only-pending` without configuring `example_status_persistence_file_path`
    Given I have not configured `example_status_persistence_file_path`
     When I run `rspec --only-pending`
     Then it should fail with "To use `--only-failures` or `--only-pending`, you must first set `config.example_status_persistence_file_path`."
