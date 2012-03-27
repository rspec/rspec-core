Feature: failures-only formatter

  The failures-only formatter outputs a format suitable for feeding back to 
  RSpec itself to have it retry failed examples. It uses the -e format to
  name the examples which have failed. 

  Scenario: Formatting example names for retry
    Given a file named "failing_spec.rb" with:
    """
    describe "Failing" do
      it "is guaranteed to fail here" do
        "fail".should eq("succeed")
      end

      it "is also guaranteed to fail here" do
        "fail".should eq("joy")
      end

      it "should fail with a 'quoted' thing" do
        "bad".should eq("worse")
      end
    end
    """
    And a file named "passing_spec.rb" with:
    """
    describe "Passing" do
      it "will pass here" do
        true.should eq(true)
      end
    end
    """
    When I run `rspec passing_spec.rb failing_spec.rb --format f`
    Then the output should contain all of these:
      |-e 'Failing is guaranteed to fail here'|
      |-e 'Failing is also guaranteed to fail here'|
      |-e 'Failing should fail with a \\'quoted\\' thing'|
    And the output should not contain any of these:
      |Passing will pass here|
    And the exit status should be 1
