Feature: Using the `--order` option

Use the `--order` option to tell RSpec how to order the files, groups, and
examples. The available ordering schemes are `defined` and `rand`.

`defined` is the default, which executes groups and examples in the order they
are defined as the spec files are loaded, with the caveat that each group
runs its examples before running its nested example groups, even if the
nested groups are defined before the examples.

Use `rand` to randomize the order of groups and examples within the groups.
Nested groups are always run from top-level to bottom-level in order to avoid
executing `before(:context)` and `after(:context)` hooks more than once, but the
order of groups at each level is randomized.

With `rand` you can also specify a seed.

Use `recently-modified` to run the most recently modified files first. You can
combine it with `--only-failures` to find the most recent failing specs. Note
that `recently-modified` and `rand` are mutually exclusive.

** Example usage **

The `defined` option is only necessary when you have `--order rand` stored in a
config file (e.g. `.rspec`) and you want to override it from the command line.

<pre><code class="bash">--order defined
--order rand
--order rand:123
--seed 123 # same as --order rand:123
--order recently-modified
</code></pre>

Scenario: Default order is `defined`
  Given a file named "example_spec.rb" with:
    """ruby
    RSpec.describe "something" do
      it "does something" do
      end

      it "in order" do
      end
    end
    """
    When I run `rspec example_spec.rb --format documentation`
    Then the output should contain:
      """
      something
        does something
        in order
      """

Scenario: Order can be psuedo randomised (seed used here to fix the ordering for tests)
  Given a file named "example_spec.rb" with:
    """ruby
    RSpec.describe "something" do
      it "does something" do
      end

      it "in order" do
      end
    end
    """
    When I run `rspec example_spec.rb --format documentation --order rand:123`
    Then the output should contain:
      """
      something
        in order
        does something
      """

Scenario: Override order to `defined` when another order is set
  Given a file named "example_spec.rb" with:
    """ruby
    RSpec.configure do |config|
      config.order = :random
      config.seed = 123
    end
    RSpec.describe "something" do
      it "does something" do
      end

      it "in order" do
      end
    end
    """
    When I run `rspec example_spec.rb --format documentation --order defined`
    Then the output should contain:
      """
      something
        does something
        in order
      """
