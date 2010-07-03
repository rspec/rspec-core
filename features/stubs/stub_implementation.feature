Feature: stub implementation

  As an rspec user, I want to stub a complete implementation, not just a
  return value.
  
  Scenario: stub implementation
    Given a file named "stub_implementation_spec.rb" with:
      """
      RSpec.configure do |c|
        c.mock_with :rspec
      end

      describe "a stubbed implementation" do
        it "works" do
          object = Object.new
          object.stub(:foo) do |arg|
            if arg == :this
              "got this"
            elsif arg == :that
              "got that"
            end
          end
          
          object.foo(:this).should == "got this"
          object.foo(:that).should == "got that"
        end
      end
      """
    When I run "rspec ./stub_implementation_spec.rb"
    Then the output should contain "1 example, 0 failures"
