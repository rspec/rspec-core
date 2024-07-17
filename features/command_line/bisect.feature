@with-clean-spec-opts
Feature: Bisect

  RSpec's `--order random` and `--seed` options help surface flickering examples that only fail when one or more other examples are executed first. It can be very difficult to isolate the exact combination of examples that triggers the failure. The `--bisect` flag helps solve that problem.

  Pass the `--bisect` option (in addition to `--seed` and any other options) and RSpec will repeatedly run subsets of your suite in order to isolate the minimal set of examples that reproduce the same failures.

  At any point during the bisect run, you can hit ctrl-c to abort and it will provide you with the most minimal reproduction command it has discovered so far.

  To get more detailed output (particularly useful if you want to report a bug with bisect), use `--bisect=verbose`.

  Background:
    Given a file named "lib/calculator.rb" with:
      """ruby
      class Calculator
        def self.add(x, y)
          x + y
        end
      end
      """
    And a file named "spec/calculator_1_spec.rb" with:
      """ruby
      require 'calculator'

      RSpec.describe "Calculator" do
        it 'adds numbers' do
          expect(Calculator.add(1, 2)).to eq(3)
        end
      end
      """
    And files "spec/calculator_2_spec.rb" through "spec/calculator_19_spec.rb" with an unrelated passing spec in each file
    And a file named "spec/calculator_20_spec.rb" with:
      """ruby
      require 'calculator'

      RSpec.describe "Monkey patched Calculator" do
        it 'does screwy math' do
          # monkey patching `Calculator` affects examples that are
          # executed after this one!
          def Calculator.add(x, y)
            x - y
          end

          expect(Calculator.add(5, 10)).to eq(-5)
        end
      end
      """

  Scenario: Use `--bisect` flag to create a minimal repro case for the ordering dependency
    When I run `rspec --seed 9876`
    Then the output should contain "20 examples, 1 failure"
    When I run `rspec --seed 9876 --bisect`
    Then bisect should succeed with output like:
      """
      Bisect started using options: "--seed 9876"
      Running suite to find failures... (0.16755 seconds)
      Starting bisect with 1 failing example and 17 non-failing examples.
      Checking that failure(s) are order-dependent... failure appears to be order-dependent

      Round 1: bisecting over non-failing examples 1-17 .. ignoring examples 10-17 (n.nnnn seconds)
      Round 2: bisecting over non-failing examples 1-9 . ignoring examples 1-5 (n.nnnn seconds)
      Round 3: bisecting over non-failing examples 6-9 .. ignoring examples 8-9 (n.nnnn seconds)
      Round 4: bisecting over non-failing examples 6-7 .. ignoring example 7 (n.nnnn seconds)
      Bisect complete! Reduced necessary non-failing examples from 17 to 1 in n.nnnn seconds.

      The minimal reproduction command is:
        rspec ./spec/calculator_1_spec.rb[1:1] ./spec/calculator_20_spec.rb[1:1] --seed 9876
      """
    When I run `rspec ./spec/calculator_20_spec.rb[1:1] ./spec/calculator_1_spec.rb[1:1] --seed 9876`
    Then the output should contain "2 examples, 1 failure"

  Scenario: Ctrl-C can be used to abort the bisect early and get the most minimal command it has discovered so far
    When I run `rspec --seed 9876 --bisect` and abort in the middle with ctrl-c
    Then bisect should fail with output like:
      """
      Bisect started using options: "--seed 9876"
      Running suite to find failures... (0.17102 seconds)
      Starting bisect with 1 failing example and 17 non-failing examples.
      Checking that failure(s) are order-dependent... failure appears to be order-dependent

      Round 1: bisecting over non-failing examples 1-17 .. ignoring examples 10-17 (n.nnnn seconds)
      Round 2: bisecting over non-failing examples 1-9 . ignoring examples 1-5 (n.nnnn seconds)
      Round 3: bisecting over non-failing examples 6-9 .. ignoring examples 8-9 (n.nnnn seconds)

      Bisect aborted!

      The most minimal reproduction command discovered so far is:
        rspec ./spec/calculator_1_spec.rb[1:1] ./spec/calculator_20_spec.rb[1:1] ./spec/calculator_6_spec.rb[1:1] --seed 9876
      """
    When I run `rspec ./spec/calculator_20_spec.rb[1:1] ./spec/calculator_1_spec.rb[1:1] ./spec/calculator_3_spec.rb[1:1] --seed 9876`
    Then the output should contain "3 examples, 1 failure"

  Scenario: Use `--bisect=verbose` to enable verbose debug mode for more detail
    When I run `rspec --seed 9876 --bisect=verbose`
    Then bisect should succeed with output like:
      """
      Bisect started using options: "--seed 9876" and bisect runner: :fork
      Running suite to find failures... (0.16528 seconds)
       - Failing examples (1):
          - ./spec/calculator_1_spec.rb[1:1]
       - Non-failing examples (17):
          - ./spec/calculator_10_spec.rb[1:1]
          - ./spec/calculator_11_spec.rb[1:1]
          - ./spec/calculator_14_spec.rb[1:1]
          - ./spec/calculator_15_spec.rb[1:1]
          - ./spec/calculator_16_spec.rb[1:1]
          - ./spec/calculator_17_spec.rb[1:1]
          - ./spec/calculator_18_spec.rb[1:1]
          - ./spec/calculator_19_spec.rb[1:1]
          - ./spec/calculator_20_spec.rb[1:1]
          - ./spec/calculator_2_spec.rb[1:1]
          - ./spec/calculator_3_spec.rb[1:1]
          - ./spec/calculator_4_spec.rb[1:1]
          - ./spec/calculator_5_spec.rb[1:1]
          - ./spec/calculator_6_spec.rb[1:1]
          - ./spec/calculator_7_spec.rb[1:1]
          - ./spec/calculator_8_spec.rb[1:1]
          - ./spec/calculator_9_spec.rb[1:1]
      Checking that failure(s) are order-dependent..
       - Running: rspec ./spec/calculator_1_spec.rb[1:1] --seed 9876 (n.nnnn seconds)
       - Failure appears to be order-dependent
      Round 1: bisecting over non-failing examples 1-17
       - Running: rspec ./spec/calculator_10_spec.rb[1:1] ./spec/calculator_11_spec.rb[1:1] ./spec/calculator_14_spec.rb[1:1] ./spec/calculator_17_spec.rb[1:1] ./spec/calculator_19_spec.rb[1:1] ./spec/calculator_1_spec.rb[1:1] ./spec/calculator_5_spec.rb[1:1] ./spec/calculator_7_spec.rb[1:1] ./spec/calculator_9_spec.rb[1:1] --seed 9876 (n.nnnn seconds)
       - Running: rspec ./spec/calculator_15_spec.rb[1:1] ./spec/calculator_16_spec.rb[1:1] ./spec/calculator_18_spec.rb[1:1] ./spec/calculator_1_spec.rb[1:1] ./spec/calculator_20_spec.rb[1:1] ./spec/calculator_2_spec.rb[1:1] ./spec/calculator_3_spec.rb[1:1] ./spec/calculator_4_spec.rb[1:1] ./spec/calculator_6_spec.rb[1:1] ./spec/calculator_8_spec.rb[1:1] --seed 9876 (n.nnnn seconds)
       - Examples we can safely ignore (8):
          - ./spec/calculator_10_spec.rb[1:1]
          - ./spec/calculator_11_spec.rb[1:1]
          - ./spec/calculator_14_spec.rb[1:1]
          - ./spec/calculator_17_spec.rb[1:1]
          - ./spec/calculator_19_spec.rb[1:1]
          - ./spec/calculator_5_spec.rb[1:1]
          - ./spec/calculator_7_spec.rb[1:1]
          - ./spec/calculator_9_spec.rb[1:1]
       - Remaining non-failing examples (9):
          - ./spec/calculator_15_spec.rb[1:1]
          - ./spec/calculator_16_spec.rb[1:1]
          - ./spec/calculator_18_spec.rb[1:1]
          - ./spec/calculator_20_spec.rb[1:1]
          - ./spec/calculator_2_spec.rb[1:1]
          - ./spec/calculator_3_spec.rb[1:1]
          - ./spec/calculator_4_spec.rb[1:1]
          - ./spec/calculator_6_spec.rb[1:1]
          - ./spec/calculator_8_spec.rb[1:1]
      Round 2: bisecting over non-failing examples 1-9
       - Running: rspec ./spec/calculator_16_spec.rb[1:1] ./spec/calculator_1_spec.rb[1:1] ./spec/calculator_20_spec.rb[1:1] ./spec/calculator_4_spec.rb[1:1] ./spec/calculator_6_spec.rb[1:1] --seed 9876 (n.nnnn seconds)
       - Examples we can safely ignore (5):
          - ./spec/calculator_15_spec.rb[1:1]
          - ./spec/calculator_18_spec.rb[1:1]
          - ./spec/calculator_2_spec.rb[1:1]
          - ./spec/calculator_3_spec.rb[1:1]
          - ./spec/calculator_8_spec.rb[1:1]
       - Remaining non-failing examples (4):
          - ./spec/calculator_16_spec.rb[1:1]
          - ./spec/calculator_20_spec.rb[1:1]
          - ./spec/calculator_4_spec.rb[1:1]
          - ./spec/calculator_6_spec.rb[1:1]
      Round 3: bisecting over non-failing examples 6-9
       - Running: rspec ./spec/calculator_16_spec.rb[1:1] ./spec/calculator_1_spec.rb[1:1] ./spec/calculator_4_spec.rb[1:1] --seed 9876 (n.nnnn seconds)
       - Running: rspec ./spec/calculator_1_spec.rb[1:1] ./spec/calculator_20_spec.rb[1:1] ./spec/calculator_6_spec.rb[1:1] --seed 9876 (n.nnnn seconds)
       - Examples we can safely ignore (2):
          - ./spec/calculator_16_spec.rb[1:1]
          - ./spec/calculator_4_spec.rb[1:1]
       - Remaining non-failing examples (2):
          - ./spec/calculator_20_spec.rb[1:1]
          - ./spec/calculator_6_spec.rb[1:1]
      Round 4: bisecting over non-failing examples 6-7
       - Running: rspec ./spec/calculator_1_spec.rb[1:1] ./spec/calculator_6_spec.rb[1:1] --seed 9876 (n.nnnn seconds)
       - Running: rspec ./spec/calculator_1_spec.rb[1:1] ./spec/calculator_20_spec.rb[1:1] --seed 9876 (n.nnnn seconds)
       - Examples we can safely ignore (1):
          - ./spec/calculator_6_spec.rb[1:1]
       - Remaining non-failing examples (1):
          - ./spec/calculator_20_spec.rb[1:1]
      Bisect complete! Reduced necessary non-failing examples from 17 to 1 in n.nnnn seconds.

      The minimal reproduction command is:
        rspec ./spec/calculator_1_spec.rb[1:1] ./spec/calculator_20_spec.rb[1:1] --seed 9876
      """
    When I run `rspec ./spec/calculator_20_spec.rb[1:1] ./spec/calculator_1_spec.rb[1:1] --seed 9876`
    Then the output should contain "2 examples, 1 failure"

  Scenario: Pick a bisect runner via a config option
    Given a file named "spec/spec_helper.rb" with:
      """
      RSpec.configure do |c|
        c.bisect_runner = :shell
      end
      """
    And a file named ".rspec" with:
      """
      --require spec_helper
      """
    When I run `rspec --seed 9876 --bisect=verbose`
    Then bisect should succeed with output like:
      """
      Bisect started using options: "--seed 9876" and bisect runner: :shell
      # ...
      The minimal reproduction command is:
        rspec ./spec/calculator_1_spec.rb[1:1] ./spec/calculator_20_spec.rb[1:1] --seed 9876
      """
