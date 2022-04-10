Feature: Randomization can be reproduced across test runs

  In Ruby, you can call `srand` for randomness and pass it to the seed you want to use. All subsequent calls to `rand`, `shuffle`,
  `sample` all be randomized the same way.

  RSpec takes care not to seed randomization directly when taking action that
  involves randomness. 

  RSpec do not trigger randomization directly for actions that involve randomness.
  RSpec does not invoke `srand`. You can choose any (or no) mechanism to seed randomization. 
  An example below shows how RSpec uses seeds for this.

  To manage seeding randomization without any help from RSpec, keep the following things in mind:

    * Do not hard-code the seed.

      You can still seed the correct randomization with a seed other than the one used by RSpec.

    * Report the seed that was chosen.

      You cannot reproduce the randomization for a given test run if you don't know the starting seed.

    * Provide a mechanism to feed the seed into the tests.

      You cannot replicate the randomness of a particular test run without hard-coding the call to `srand`.

  Background:
    Given a file named ".rspec" with:
      """
      --require spec_helper
      """

    Given a file named "spec/random_spec.rb" with:
      """ruby
      RSpec.describe 'randomized example' do
        it 'prints random numbers' do
          puts 5.times.map { rand(99) }.join("-")
        end
      end
      """

  Scenario: Specifying a seed using `srand` provides predictable randomization
    Given a file named "spec/spec_helper.rb" with:
      """ruby
      srand 123
      """
    When I run `rspec`
    Then the output should contain "66-92-98-17-83"

  Scenario: Passing the RSpec seed to `srand` provides predictable randomization
    Given a file named "spec/spec_helper.rb" with:
      """ruby
      srand RSpec.configuration.seed
      """
    When I run `rspec --seed 123`
    Then the output should contain "66-92-98-17-83"
