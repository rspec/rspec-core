Feature: JUnit Formatter

  In order to import the result of running my specs into a continuous integration server like Hudson
  As an RSpec user
  I want output formatted as JUnit XML
  
  @announce
  Scenario:
    Given a file named "string_spec.rb" with:
      """
      describe String do
        it "has a succeeding example" do
          "foo".length.should == 3
        end
        
        it "has a pending example"
        
        it "has a failing example" do
          "foo".reverse.should == "ofo"
        end
      end
      """
      And a file named "integer_spec.rb" with:
      """
      describe Integer do
        it "has an implemented but waiting example" do
          pending
        end
      end
      """
      
      When I run `rspec --format junit string_spec.rb integer_spec.rb`
      
      Then the output should be xml
      
      And the output xml should contain a /testsuite[@tests=4 and @failures=1 and @errors=0 and @time and @timestamp]
      And the output xml should contain a /testsuite/properties
      And the output xml should contain 4 /testsuite/testcase
      And the output xml should contain 2 /testsuite/testcase[skipped]
      And the output xml should contain a /testsuite/testcase[failure]
      
      And the output xml should contain 4 //testcase[@classname and @name and @time]
      And the output xml should contain 3 //testcase[contains(@classname, "/string_spec.rb")]
      And the output xml should contain a //testcase[contains(@classname, "/integer_spec.rb")]
      
      And the output xml should contain a //testcase[@name="String has a succeeding example"]
      And the output xml should contain a //testcase[@name="String has a pending example"]/skipped
      And the output xml should contain a //testcase[@name="String has a failing example"]/failure[contains(@message, "expected:") and @type="RSpec::Expectations::ExpectationNotMetError" and text()]
      And the output xml should contain a //testcase[@name="Integer has an implemented but waiting example"]/skipped
