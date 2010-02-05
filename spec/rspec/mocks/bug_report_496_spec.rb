require 'spec_helper'

module BugReport496
  class BaseClass
  end

  class SubClass < BaseClass
  end

  describe "a message expectation on a base class object" do
    BaseClass.should_receive(:new).once
    SubClass.new
  end
end

