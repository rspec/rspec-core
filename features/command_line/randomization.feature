Feature: Randomization can be reproduced across test runs

  Background:
    Given a file named "random_spec.rb" with:
      """ruby
      describe 'randomized example' do
        it 'prints random numbers' do
          5.times { print rand(99) }
        end
      end
      """

  Scenario: Specifying a seed provides predictable randomization
    When I run `rspec . --seed 123`
    Then the output should contain "6692981783"
