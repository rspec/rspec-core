Feature: Helper methods

  Helper methods defined in an example group can be used in any examples in
  that group or any subgroups.  Examples in parent or sibling example groups
  will not have access.

  RSpec also provides the `let` macro for defining a memoized helper method.
  The value will be cached across multiple calls in the same example but not
  across examples.  You can use `let!` to cause the method to be called in a
  `before(:each)` hook.

  Scenario: Helper methods can be accessed from examples in group and subgroups
    Given a file named "helper_method_spec.rb" with:
      """
      describe "helper methods" do
        def my_helper
          "foo"
        end

        it "has access to the helper method" do
          my_helper.should == "foo"
        end

        describe "a subgroup" do
          it "also has access to the helper method" do
            my_helper.should == "foo"
          end
        end
      end
      """
    When I run "rspec helper_method_spec.rb"
    Then the output should contain "2 examples, 0 failures"

  Scenario: Helper methods cannot be accessed from examples in parent or sibling groups
    Given a file named "helper_methods_spec.rb" with:
      """
      describe "helper methods" do
        describe "subgroup 1" do
          def my_helper
            "foo"
          end
        end

        it "does not have access in the parent group" do
          expect { my_helper }.to raise_error(/undefined local variable or method `my_helper'/)
        end

        describe "subgroup 2" do
          it "does not have access in a sibling group" do
            expect { my_helper }.to raise_error(/undefined local variable or method `my_helper'/)
          end
        end
      end
      """
    When I run "rspec helper_methods_spec.rb"
    Then the output should contain "2 examples, 0 failures"

  Scenario: Use let to define memoized helper method
    Given a file named "let_spec.rb" with:
      """
      $count = 0
      describe "let" do
        let(:count) { $count += 1 }

        it "memoizes the value" do
          count.should == 1
          count.should == 1
        end

        it "is not cached across examples" do
          count.should == 2
        end
      end
      """
    When I run "rspec let_spec.rb"
    Then the output should contain "2 examples, 0 failures"

  Scenario: Use let! to define a memoized helper method that is called in a before hook
    Given a file named "let_bang_spec.rb" with:
      """
      $count = 0
      describe "let!" do
        invocation_order = []

        let!(:count) do
          invocation_order << :let!
          $count += 1
        end

        it "calls the helper method in a before hook" do
          invocation_order << :example
          invocation_order.should == [:let!, :example]
          count.should == 1
        end
      end
      """
    When I run "rspec let_bang_spec.rb"
    Then the output should contain "1 example, 0 failure"
