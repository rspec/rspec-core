require 'spec_helper'

module RSpec
  module Mocks
    describe "Example with stubbed and then called message" do
      it "fails if the message is expected and then subsequently not called again" do
        double = double("mock", :msg => nil)
        double.msg
        double.should_receive(:msg)
        lambda { double.rspec_verify }.should raise_error(RSpec::Mocks::MockExpectationError)
      end

      it "outputs arguments of all similar calls" do
        double = double('double', :foo => true)
        double.should_receive(:foo).with('first')
        double.foo('second')
        double.foo('third')
        lambda do
          double.rspec_verify
        end.should raise_error(%Q|Double "double" received :foo with unexpected arguments\n  expected: ("first")\n       got: ("second"), ("third")|)
        double.rspec_reset
      end
    end

    describe "Example with stubbed with args and expectation with no args" do
      it "matches any args even if previously stubbed with arguments" do
        double = double("mock")
        double.stub(:foo).with(3).and_return("stub")
        double.should_receive(:foo).at_least(:once).and_return("expectation")
        double.foo
        double.rspec_verify
      end
    end

  end
end
