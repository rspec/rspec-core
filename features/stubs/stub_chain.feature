Feature: stub_chain

  Scenario: stub a chain of methods
    Given a file named "stub_chain_spec.rb" with:
      """
      describe "stubbing a chain of methods" do
        subject { Object.new }

        context "given symbols as methods" do

          it "returns the correct value" do
            subject.stub_chain(:one, :two, :three).and_return(:four)

            subject.one.two.three.should eql(:four)
          end

        end

        context "given a string of methods separated by dots" do

          it "returns the correct value" do
            subject.stub_chain("one.two.three").and_return(:four)

            subject.one.two.three.should eql(:four)
          end

        end
      end
      """
    When I run "rspec stub_chain_spec.rb"
    Then the output should contain "2 examples, 0 failures"