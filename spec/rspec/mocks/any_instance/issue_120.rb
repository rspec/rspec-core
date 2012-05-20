require 'spec_helper'

module RSpec
  module Mocks
    describe "#any_instance" do
      it "doesn't cause an infinite loop when used in conjunction with dup" do
        Object.any_instance.stub(:some_method)
        o = Object.new
        o.some_method
        lambda { o.dup.some_method }.should_not raise_error(SystemStackError)
      end
    end
  end
end