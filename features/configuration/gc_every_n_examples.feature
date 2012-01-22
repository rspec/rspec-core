Feature: gc_every_n_examples

  Use `config.gc_every_n_examples` to ensure GC happens less frequently than
  might otherwise happen.

  Scenario: Use gc_every_n_examples to ensure a GC happens after every example.
    Given a file named "gc_every_n_examples_spec.rb" with:
      """
      RSpec.configure do |c|
        c.gc_every_n_examples = 1
      end

      describe "an example group" do
        it "does one thing" do
        end

        it "does another thing" do
        end
      end

      describe "another example group" do
        it "does one thing" do
        end

        it "does another thing" do
        end
      end
      """
    When I run `rspec gc_every_n_examples_spec.rb --profile --format doc`
    Then the output should contain "including 4 forced GC cycle(s)"

  Scenario: Use gc_every_n_examples to ensure no GC happens.
    Given a file named "gc_every_n_examples_spec.rb" with:
      """
      RSpec.configure do |c|
        c.gc_every_n_examples = 10000
        # Setting this here because GC can happen up until the GC.disable call
        # in RSpec::Core::Configuration#gc_every_n_examples=.
        #
        # Also note that Ruby 1.8.x doesn't have the GC.count method, so we
        # just fake it and move on.
        if(GC.respond_to?(:count))
          gc_count_before = GC.count
          c.after(:suite) do
            gc_count_after = GC.count
            puts "Had #{gc_count_after - gc_count_before} actual GC cycles."
          end
        else
          c.after(:suite) do
            puts "Had 0 actual GC cycles."
          end
        end
      end

      describe "an example group" do
        it "does one thing" do
        end

        it "does another thing" do
        end
      end

      describe "another example group" do
        it "does one thing" do
        end

        it "does another thing" do
        end
      end
      """
    When I run `rspec gc_every_n_examples_spec.rb --profile --format doc`
    Then the output should contain "Had 0 actual GC cycles."
    And the output should not contain "forced GC cycle(s)"
