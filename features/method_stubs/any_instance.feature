Feature: stub on any instance of a class

  Use `any_instance.stub` on a class to tell any instance of that class to
  return a value (or values) in response to a given message.  If no instance
  receives the message, nothing happens.

  Messages can be stubbed on any class, including those in Ruby's core library.

  Scenario: any_instance stub with a single return value
    Given a file named "example_spec.rb" with:
      """
      describe "any_instance.stub" do
        it "returns the specified value on any instance of the class" do
          Object.any_instance.stub(:foo).and_return(:return_value)

          o = Object.new
          o.foo.should eq(:return_value)
        end
      end
      """
    When I run `rspec example_spec.rb`
    Then the examples should all pass
    
  Scenario: any_instance stub with a hash
    Given a file named "example_spec.rb" with:
      """
      describe "any_instance.stub" do
        context "with a hash" do
          it "returns the hash values on any instance of the class" do
            Object.any_instance.stub(:foo => 'foo', :bar => 'bar')

            o = Object.new
            o.foo.should eq('foo')
            o.bar.should eq('bar')
          end
        end
      end
      """
    When I run `rspec example_spec.rb`
    Then the examples should all pass  
    
  Scenario: any_instance stub with specific arguments matchers
    Given a file named "example_spec.rb" with:
      """
      describe "any_instance.stub" do
        context "with arguments" do
          it "returns the stubbed value when arguments match" do
            Object.any_instance.stub(:foo).with(:param_one, :param_two).and_return(:result_one)
            Object.any_instance.stub(:foo).with(:param_three, :param_four).and_return(:result_two)
          
            o = Object.new
            o.foo(:param_one, :param_two).should eq(:result_one)
            o.foo(:param_three, :param_four).should eq(:result_two)
          end
        end
      end
      """
    When I run `rspec example_spec.rb`
    Then the examples should all pass