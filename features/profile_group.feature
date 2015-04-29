Feature: Profile group example

  @wip
  Scenario: Slowest before hook should be show
    Given a file named "spec/example_spec.rb" with:
      """ruby
      RSpec.describe "slow before context hook" do
        before(:context) do
          sleep 0.2
        end
        it "example" do
          expect(10).to eq(10)
        end
      end

      RSpec.describe "slow example" do
        it "slow example" do
          sleep 0.1
          expect(10).to eq(10)
        end
      end
      """
    When I run `rspec spec --profile 1`
    Then the output should contain "slow before context hook"
