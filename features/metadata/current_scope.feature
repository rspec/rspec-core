Feature: RSpec provides the current scope as RSpec.current_scope

  You can detect which rspec scope your helper methods or library code is executing in.
  This is useful if for example, your method only makes sense to call in a certain context.

  Scenario: Detecting the current scope
    Given a file named "current_scope_spec.rb" with:
      """ruby
      # Outside of the test lifecycle, the current scope is `:suite`
      exit(1)  unless RSpec.current_scope == :suite

      at_exit do
        exit(1) unless RSpec.current_scope == :suite
      end

      RSpec.configure do |c|
        c.before :suite do
          expect(RSpec.current_scope).to eq(:before_suite_hook)
        end

        c.before :context do
          expect(RSpec.current_scope).to eq(:before_context_hook)
        end

        c.before :example do
          expect(RSpec.current_scope).to eq(:before_example_hook)
        end

        c.around :example do |ex|
          expect(RSpec.current_scope).to eq(:before_example_hook)
          ex.run
          expect(RSpec.current_scope).to eq(:after_example_hook)
        end

        c.after :example do
          expect(RSpec.current_scope).to eq(:after_example_hook)
        end

        c.after :context do
          expect(RSpec.current_scope).to eq(:after_context_hook)
        end

        c.after :suite do
          expect(RSpec.current_scope).to eq(:after_suite_hook)
        end
      end

      RSpec.describe "RSpec.current_scope" do
        before :context do
          expect(RSpec.current_scope).to eq(:before_context_hook)
        end

        before :example do
          expect(RSpec.current_scope).to eq(:before_example_hook)
        end

        around :example do |ex|
          expect(RSpec.current_scope).to eq(:before_example_hook)
          ex.run
          expect(RSpec.current_scope).to eq(:after_example_hook)
        end

        after :example do
          expect(RSpec.current_scope).to eq(:after_example_hook)
        end

        after :context do
          expect(RSpec.current_scope).to eq(:after_context_hook)
        end

        it "is :example in an example" do
          expect(RSpec.current_scope).to eq(:example)
        end

        it "works for multiple examples" do
          expect(RSpec.current_scope).to eq(:example)
        end

        describe "in nested describe blocks" do
          it "still works" do
            expect(RSpec.current_scope).to eq(:example)
          end
        end
      end
      """
    When I run `rspec current_scope_spec.rb`
    Then the examples should all pass
