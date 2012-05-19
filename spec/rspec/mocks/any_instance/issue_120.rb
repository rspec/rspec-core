require 'spec_helper'

module RSpec
  module Mocks
    describe "#any_instance" do
      it "doesn't cause an infinite loop when used in conjunction with dup" do
        Object.any_instance.stub(:some_method)
        o = Object.new
        o.some_method
        o.dup.some_method
      end
    end
  end
end