Feature: as_null_object method stub

  Use the `as_null_object` method to ignore any messages that
  aren't explicitly set as stubs or message expectations.

  Scenario: as_null_object implementation
    Given a file named "as_null_object_spec.rb" with:
      """
      describe "a double with as_null_object called" do
        subject { double('null object').as_null_object }

        it "responds to any method that is not defined" do
          subject.should respond_to(:an_undefined_method)
        end

        it "allows explicit stubs" do
          subject.stub(:foo) { "bar" }
          subject.foo.should eq("bar")
        end

        it "allows explicit expectations" do
          subject.should_receive(:something)
          subject.something
        end
      end
      """
    When I run `rspec as_null_object_spec.rb`
    Then the examples should all pass