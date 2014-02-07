@wip @announce
Feature: Regression tests for legacy custom formatters

  Background:
    Given a file named "spec/passing_and_failing_spec.rb" with:
      """ruby
      RSpec.describe "Some examples" do
        it "passes" do
          expect(1).to eq(1)
        end

        it "fails" do
          expect(1).to eq(2)
        end

        context "nested" do
          it "passes" do
            expect(1).to eq(1)
          end

          it "fails" do
            expect(1).to eq(2)
          end
        end
      end
      """
      And a file named "spec/bar_spec.rb" with:
      """ruby
      RSpec.describe "Some pending examples" do
        context "pending" do
          it "is reported as pending" do
            pending { expect(1).to eq(2) }
          end

          it "is reported as failing" do
            pending { expect(1).to eq(1) }
          end
        end

        context "skip" do
          it "does not run the example" do
            skip
          end
        end
      end
      """

  Scenario: Use fuubar formatter
    When I run `rspec --format Fuubar`
    Then the output should contain "TBD"

  Scenario: Use fivemat formatter
    When I run `rspec --format Fivemat`
    Then the output should contain "TBD"

  Scenario: Use nyancat formatter
    When I run `rspec --format NyanCatFormatter`
    Then the output should contain "TBD"

