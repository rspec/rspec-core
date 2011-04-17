Feature: as_null_object method stub

  Use the `as_null_object` method to ignore any messages that
  aren't explicitly set as stubs or message expectations.

  Scenario: double acting as_null_object 
    Given a file named "as_null_object_spec.rb" with:
      """
      describe "a double with as_null_object called" do
        let(:null_object) { double('null object').as_null_object }

        it "responds to any method that is not defined" do
          null_object.should respond_to(:an_undefined_method)
        end

        it "allows explicit stubs" do
          null_object.stub(:foo) { "bar" }
          null_object.foo.should eq("bar")
        end

        it "allows explicit expectations" do
          null_object.should_receive(:something)
          null_object.something
        end
      end
      """
    When I run `rspec as_null_object_spec.rb`
    Then the examples should all pass
