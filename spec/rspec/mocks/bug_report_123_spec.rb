require 'spec_helper'

describe 'with'  do
  it "should ask the user to stub a default value first if the message might be received with other args as well" do
    obj = Object.new
    obj.should_receive(:foobar).with(1)
    obj.foobar(1)
    lambda{ obj.foobar(2) }.should raise_error(RSpec::Mocks::MockExpectationError, /Please stub a default value first if message might be received with other args as well./)
  end
end
