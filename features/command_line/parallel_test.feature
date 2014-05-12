Feature: `--parallel-test` option

  Use the `--parallel-test` option to have RSpec print your suite's formatter output
  without running any examples or hooks.

  Scenario: Using `--parallel-test`
    Given a file named "spec/parallel_test_spec.rb" with:
      """ruby
      RSpec.configure do |c|
        c.before(:suite) { puts "before suite" }
        c.after(:suite)  { puts "after suite"  }
      end

      RSpec.describe "parallel run" do
        before(:context) { puts "before context" }
        before(:example) { puts "before example" }

        it "thread 0 example" do
          fail
        end

        it "thread 1 example" do
          pass
        end

        it "thread 2 example" do
          pass
        end

        after(:example) { puts "after example" }
        after(:context) { puts "after context" }
      end
      """
    When I run `rspec --parallel-test 3`
    Then the output should contain "3 examples, 1 failure"
     And the output should contain "before suite"
     And the output should contain "after suite"
     And the output should contain "before context"
     And the output should contain "after context"
     And the output should contain "before example"
     And the output should contain "after example"
