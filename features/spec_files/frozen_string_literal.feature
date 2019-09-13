Feature: frozen string literal

  Scenario: `.spec`
    Given a file named "no_frozen_string_literal_spec.rb" with:
      """ruby
      RSpec.describe "something" do
        it "does something" do
          a = 'hello'
          a << ' world'
          expect(a).to eq('hello world')
        end
      end
      """
    When I run `rspec no_frozen_string_literal_spec.rb`
    Then the examples should all pass

