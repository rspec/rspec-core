Feature: manual examples

  RSpec offers four ways to indicate that an example is disabled manual
  some action.

  Scenario: manual implementation
    Given a file named "example_without_block_spec.rb" with:
      """
      describe "an example" do
        it "is a manual example"
      end
      """
    When I run `rspec example_without_block_spec.rb`
    Then the exit status should be 0
    And the output should contain "1 example, 0 failures, 1 manual"
    And the output should contain "Not yet implemented"
    And the output should contain "example_without_block_spec.rb:2"

  Scenario: temporarily manual by prefixing `it`, `specify`, or `example` with an m
    Given a file named "manual_prefix_spec.rb" with:
      """
      describe "an example" do
        mit "is manual using mit" do
        end

        mspecify "is manual using mspecify" do
        end

        mexample "is manual using mexample" do
        end
      end
      """
    When I run `rspec temporarily_manual_spec.rb`
    Then the exit status should be 0
    And the output should contain "3 examples, 0 failures, 3 manual"
    And the output should contain:
      """
      manual:
        an example is manual using mit
          # Temporarily disabled with mit
          # ./temporarily_manual_spec.rb:2
        an example is manual using mpecify
          # Temporarily disabled with mspecify
          # ./temporarily_manual_spec.rb:5
        an example is manual using mexample
          # Temporarily disabled with mexample
          # ./temporarily_manual_spec.rb:8
      """

  Scenario: example with no docstring and manual method using documentation formatter
    Given a file named "manual_with_no_docstring_spec.rb" with:
      """
      describe "an example" do
        it "checks something" do
          (3+4).should eq(7)
        end
        specify do
          manual
        end
      end
      """
    When I run `rspec manual_with_no_docstring_spec.rb --format documentation`
    Then the exit status should be 0
    And the output should contain "2 examples, 0 failures, 1 manual"
    And the output should contain:
      """
      an example
        checks something
        example at ./manual_with_no_docstring_spec.rb:5 (manual: No reason given)
      """

  Scenario: manual with no docstring using documentation formatter
    Given a file named "manual_with_no_docstring_spec.rb" with:
      """
      describe "an example" do
        it "checks something" do
          (3+4).should eq(7)
        end
        manual do
          "string".reverse.should eq("gnirts")
        end
      end
      """
    When I run `rspec manual_with_no_docstring_spec.rb --format documentation`
    Then the exit status should be 0
    And the output should contain "2 examples, 0 failures, 1 manual"
    And the output should contain:
      """
      an example
        checks something
        example at ./manual_with_no_docstring_spec.rb:5 (manual: No reason given)
      """

  Scenario: conditionally manual examples
    Given a file named "conditionally_manual_spec.rb" with:
      """
      describe "a failing spec" do
        def run_test; raise "failure"; end

        it "is manual when manual with a true :if condition" do
          manual("true :if", :if => true) { run_test }
        end

        it "fails when manual with a false :if condition" do
          manual("false :if", :if => false) { run_test }
        end

        it "is manual when manual with a false :unless condition" do
          manual("false :unless", :unless => false) { run_test }
        end

        it "fails when manual with a true :unless condition" do
          manual("true :unless", :unless => true) { run_test }
        end
      end

      describe "a passing spec" do
        def run_test; true.should be(true); end

        it "fails when manual with a true :if condition" do
          manual("true :if", :if => true) { run_test }
        end

        it "passes when manual with a false :if condition" do
          manual("false :if", :if => false) { run_test }
        end

        it "fails when manual with a false :unless condition" do
          manual("false :unless", :unless => false) { run_test }
        end

        it "passes when manual with a true :unless condition" do
          manual("true :unless", :unless => true) { run_test }
        end
      end
      """
    When I run `rspec ./conditionally_manual_spec.rb`
    Then the output should contain "8 examples, 4 failures, 2 manual"
    And the output should contain:
      """
      manual:
        a failing spec is manual when manual with a true :if condition
          # true :if
          # ./conditionally_manual_spec.rb:4
        a failing spec is manual when manual with a false :unless condition
          # false :unless
          # ./conditionally_manual_spec.rb:12
      """
    And the output should contain:
      """
        1) a failing spec fails when manual with a false :if condition
           Failure/Error: def run_test; raise "failure"; end
      """
    And the output should contain:
      """
        2) a failing spec fails when manual with a true :unless condition
           Failure/Error: def run_test; raise "failure"; end
      """
    And the output should contain:
      """
        3) a passing spec fails when manual with a true :if condition FIXED
           Expected manual 'true :if' to fail. No Error was raised.
      """
    And the output should contain:
      """
        4) a passing spec fails when manual with a false :unless condition FIXED
           Expected manual 'false :unless' to fail. No Error was raised.
      """
