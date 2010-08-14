require 'spec_helper'

module RSpec
  module Mocks
    describe "mock failure" do
      
      it "tells you when it receives the right message with the wrong args" do
        double = double("foo")
        double.should_receive(:bar).with("message")
        lambda {
          double.bar("different message")
        }.should raise_error(RSpec::Mocks::MockExpectationError, %Q{Double "foo" received :bar with unexpected arguments\n  expected: ("message")\n       got: ("different message")})
        double.rspec_reset # so the example doesn't fail
      end

      pending "tells you when it receives the right message with the wrong args if you stub the method (fix bug 15719)" do
        # NOTE - for whatever reason, if you use a the block style of pending here,
        # rcov gets unhappy. Don't know why yet.
        double = double("foo")
        double.stub(:bar)
        double.should_receive(:bar).with("message")
        lambda {
          double.bar("different message")
        }.should raise_error(RSpec::Mocks::MockExpectationError, %Q{Double 'foo' expected :bar with ("message") but received it with ("different message")})
        double.rspec_reset # so the example doesn't fail
      end
    end
  end
end
