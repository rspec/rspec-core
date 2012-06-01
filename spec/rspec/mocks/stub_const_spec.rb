require 'spec_helper'

TOP_LEVEL_VALUE_CONST = 7

class TestClass
  M = :m
  N = :n

  class Nested
    class NestedEvenMore
    end
  end
end

module RSpec
  module Mocks
    describe "Constant Stubbing" do
      include RSpec::Mocks::RecursiveConstMethods

      def reset_rspec_mocks
        ::RSpec::Mocks.space.reset_all
      end

      shared_examples_for "loaded constant stubbing" do |const_name|
        let!(:original_const_value) { const }
        after { change_const_value_to(original_const_value) }

        define_method :const do
          recursive_const_get(const_name)
        end

        define_method :parent_const do
          recursive_const_get("Object::" + const_name.sub(/(::)?[^:]+\z/, ''))
        end

        define_method :last_const_part do
          const_name.split('::').last
        end

        def change_const_value_to(value)
          parent_const.send(:remove_const, last_const_part)
          parent_const.const_set(last_const_part, value)
        end

        it 'allows it to be stubbed' do
          const.should_not eq(7)
          stub_const(const_name, 7)
          const.should eq(7)
        end

        it 'resets it to its original value when rspec clears its mocks' do
          original_value = const
          original_value.should_not eq(:a)
          stub_const(const_name, :a)
          reset_rspec_mocks
          const.should be(original_value)
        end

        it 'returns the original value' do
          orig_value = const
          returned_value = stub_const(const_name, 7)
          returned_value.should be(orig_value)
        end
      end

      shared_examples_for "unloaded constant stubbing" do |const_name|
        before { recursive_const_defined?(const_name).should be_false }

        define_method :const do
          recursive_const_get(const_name)
        end

        define_method :parent_const do
          recursive_const_get("Object::" + const_name.sub(/(::)?[^:]+\z/, ''))
        end

        define_method :last_const_part do
          const_name.split('::').last
        end

        def change_const_value_to(value)
          parent_const.send(:remove_const, last_const_part)
          parent_const.const_set(last_const_part, value)
        end

        it 'allows it to be stubbed' do
          stub_const(const_name, 7)
          const.should eq(7)
        end

        it 'removes the constant when rspec clears its mocks' do
          stub_const(const_name, 7)
          reset_rspec_mocks
          recursive_const_defined?(const_name).should be_false
        end

        it 'returns nil since it was not originally set' do
          stub_const(const_name, 7).should be_nil
        end

        it 'ignores the :transfer_nested_constants option if passed' do
          stub = Module.new
          stub_const(const_name, stub, :transfer_nested_constants => true)
          stub.constants.should eq([])
        end
      end

      describe "#stub_const" do
        context 'for a loaded unnested constant' do
          it_behaves_like "loaded constant stubbing", "TestClass"

          it 'can be stubbed multiple times but still restores the original value properly' do
            orig_value = TestClass
            stub1, stub2 = Module.new, Module.new
            stub_const("TestClass", stub1)
            stub_const("TestClass", stub2)

            reset_rspec_mocks
            TestClass.should be(orig_value)
          end

          it 'allows nested constants to be transferred to a stub module' do
            tc_nested = TestClass::Nested
            stub = Module.new
            stub_const("TestClass", stub, :transfer_nested_constants => true)
            stub::M.should eq(:m)
            stub::N.should eq(:n)
            stub::Nested.should be(tc_nested)
          end

          it 'allows nested constants to be selectively transferred to a stub module' do
            stub = Module.new
            stub_const("TestClass", stub, :transfer_nested_constants => [:M, :N])
            stub::M.should eq(:m)
            stub::N.should eq(:n)
            defined?(stub::Nested).should be_false
          end

          it 'raises an error if asked to transfer nested constants but given an object that does not support them' do
            original_tc = TestClass
            stub = Object.new
            expect {
              stub_const("TestClass", stub, :transfer_nested_constants => true)
            }.to raise_error(ArgumentError)

            TestClass.should be(original_tc)

            expect {
              stub_const("TestClass", stub, :transfer_nested_constants => [:M])
            }.to raise_error(ArgumentError)

            TestClass.should be(original_tc)
          end

          it 'raises an error if asked to transfer nested constants on a constant that does not support nested constants' do
            stub = Module.new
            expect {
              stub_const("TOP_LEVEL_VALUE_CONST", stub, :transfer_nested_constants => true)
            }.to raise_error(ArgumentError)

            TOP_LEVEL_VALUE_CONST.should eq(7)

            expect {
              stub_const("TOP_LEVEL_VALUE_CONST", stub, :transfer_nested_constants => [:M])
            }.to raise_error(ArgumentError)

            TOP_LEVEL_VALUE_CONST.should eq(7)
          end

          it 'raises an error if asked to transfer a nested constant that is not defined' do
            original_tc = TestClass
            defined?(TestClass::V).should be_false
            stub = Module.new

            expect {
              stub_const("TestClass", stub, :transfer_nested_constants => [:V])
            }.to raise_error(/cannot transfer nested constant.*V/i)

            TestClass.should be(original_tc)
          end
        end

        context 'for a loaded nested constant' do
          it_behaves_like "loaded constant stubbing", "TestClass::Nested"
        end

        context 'for a loaded deeply nested constant' do
          it_behaves_like "loaded constant stubbing", "TestClass::Nested::NestedEvenMore"
        end

        context 'for an unloaded unnested constant' do
          it_behaves_like "unloaded constant stubbing", "X"
        end

        context 'for an unloaded nested constant' do
          it_behaves_like "unloaded constant stubbing", "X::Y"

          it 'removes the root constant when rspec clears its mocks' do
            defined?(X).should be_false
            stub_const("X::Y", 7)
            reset_rspec_mocks
            defined?(X).should be_false
          end
        end

        context 'for an unloaded deeply nested constant' do
          it_behaves_like "unloaded constant stubbing", "X::Y::Z"

          it 'removes the root constant when rspec clears its mocks' do
            defined?(X).should be_false
            stub_const("X::Y::Z", 7)
            reset_rspec_mocks
            defined?(X).should be_false
          end
        end

        context 'for an unloaded constant nested within a loaded constant' do
          it_behaves_like "unloaded constant stubbing", "TestClass::X"

          it 'removes the unloaded constant but leaves the loaded constant when rspec resets its mocks' do
            defined?(TestClass).should be_true
            defined?(TestClass::X).should be_false
            stub_const("TestClass::X", 7)
            reset_rspec_mocks
            defined?(TestClass).should be_true
            defined?(TestClass::X).should be_false
          end

          it 'raises a helpful error if it cannot be stubbed due to an intermediary constant that is not a module' do
            TestClass::M.should be_a(Symbol)
            expect { stub_const("TestClass::M::X", 5) }.to raise_error(/cannot stub/i)
          end
        end

        context 'for an unloaded constant nested deeply within a deeply nested loaded constant' do
          it_behaves_like "unloaded constant stubbing", "TestClass::Nested::NestedEvenMore::X::Y::Z"

          it 'removes the first unloaded constant but leaves the loaded nested constant when rspec resets its mocks' do
            defined?(TestClass::Nested::NestedEvenMore).should be_true
            defined?(TestClass::Nested::NestedEvenMore::X).should be_false
            stub_const("TestClass::Nested::NestedEvenMore::X::Y::Z", 7)
            reset_rspec_mocks
            defined?(TestClass::Nested::NestedEvenMore).should be_true
            defined?(TestClass::Nested::NestedEvenMore::X).should be_false
          end
        end
      end
    end
  end
end

