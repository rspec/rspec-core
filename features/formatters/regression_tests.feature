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
      And a file named "spec/pending_spec.rb" with:
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
      end
      """

  Scenario: Use fuubar formatter
    When I run `rspec --format Fuubar`
    Then the output should contain "Progress: |============"
     And the output should contain "6 examples, 3 failures, 1 pending"
     But the output should not contain any error backtraces

  @wip @announce
  Scenario: Use nyancat formatter
    When I run `rspec --format NyanCatFormatter`
    Then the output should contain "TBD"

