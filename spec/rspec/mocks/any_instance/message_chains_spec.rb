require 'spec_helper'

module RSpec
  module Mocks
    module AnyInstance
      describe MessageChains do
        let(:chains) { MessageChains.new }
        let(:stub_chain) { StubChain.new }
        let(:expectation_chain) { ExpectationChain.new }
        
        it "knows if a method does not have an expectation set on it" do
          chains.add(:method_name, stub_chain)
          chains.has_expectation?(:method_name).should be_false
        end
        
        it "knows if a method has an expectation set on it" do
          chains.add(:method_name, stub_chain)
          chains.add(:method_name, expectation_chain)
          chains.has_expectation?(:method_name).should be_true
        end
        
        context "creating stub chains" do
          it "understands how to add a stub chain for a method" do
            chains.add(:method_name, stub_chain)
            chains[:method_name].should eq([stub_chain])
          end

          it "allows multiple stub chains for a method" do
            chains.add(:method_name, stub_chain)
            chains.add(:method_name, another_stub_chain = StubChain.new)
            chains[:method_name].should eq([stub_chain, another_stub_chain])
          end
        end
      end
    end
  end
end