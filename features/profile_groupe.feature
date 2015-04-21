Feature: Profile group example

  Scenario: Slowest before hook should be show
    Given a file named "spec/example_spec.rb" with:
      """ruby
      RSpec.describe "slow before context hook" do
        before(:context) do
          sleep 0.4
        end
        it "example" do
          expect(10).to eq(10)
        end
      end

      RSpec.describe "slow example" do
        it "slow example" do
          sleep 0.2
          expect(10).to eq(10)
        end
      end
      RSpec.describe "slow example 1" do
        it "slow example" do
          sleep 0.2
          expect(10).to eq(10)
        end
      end
      RSpec.describe "slow example 2" do
        it "slow example" do
          sleep 0.2
          expect(10).to eq(10)
        end
      end
      RSpec.describe "slow example 3" do
        it "slow example" do
          sleep 0.2
          expect(10).to eq(10)
        end
      end
      RSpec.describe "slow example 4" do
        it "slow example" do
          sleep 0.2
          expect(10).to eq(10)
        end
      end
      RSpec.describe "slow example 5" do
        it "slow example" do
          sleep 0.2
          expect(10).to eq(10)
        end
      end
      RSpec.describe "slow example 6" do
        it "slow example" do
          sleep 0.2
          expect(10).to eq(10)
        end
      end
      RSpec.describe "slow example 7" do
        it "slow example" do
          sleep 0.2
          expect(10).to eq(10)
        end
      end
      RSpec.describe "slow example 8" do
        it "slow example" do
          sleep 0.2
          expect(10).to eq(10)
        end
      end
      RSpec.describe "slow example 9" do
        it "slow example" do
          sleep 0.2
          expect(10).to eq(10)
        end
      end
      """
    When I run `rspec spec --profile`
    Then the output should contain "slow before context hook"
