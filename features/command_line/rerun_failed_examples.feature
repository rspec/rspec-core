Feature: Rerun failed examples only

  Using a combination of the failures-only formatter and the -O option to
  read options from a file, we can get rspec to retry failed examples.

  Scenario: rerun failed examples by name
    Given a file named "spec/example_spec.rb" with:
    """
    describe "retry" do
      it "should not rerun this one" do
        true.should == true
      end
      it "should rerun this one" do
        false.should == true
      end
      it "should also rerun this one" do
        false.should == true
      end
    end
    """
    When I run `rspec ./spec/example_spec.rb --format f -o failures.txt --format d -o first_run.txt`
    Then the exit status should be 1
    And the file "first_run.txt" should contain "3 examples, 2 failures"
    And the file "failures.txt" should contain:
      """
      -e 'retry should rerun this one'
      -e 'retry should also rerun this one'
      """
    When I run `rspec ./spec/example_spec.rb -O failures.txt --format d`
    Then the exit status should be 1
    And the output should contain all of these:
      |should rerun this one|
      |should also rerun this one|
      |2 failures|
    And the output should not contain any of these:
      |should not rerun this one|


