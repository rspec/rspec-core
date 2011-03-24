require 'spec_helper'

module RSpec
  module Mocks
    describe "#any_instance" do
      class CustomErrorForAnyInstanceSpec < StandardError;end

      let(:klass) do
        Class.new do
          def existing_method; 2; end
        end
      end

      context "invocation order" do
        context "#stub" do
          it "raises an error if 'stub' follows 'with'" do
            lambda{ klass.any_instance.with("1").stub(:foo) }.should raise_error(NoMethodError)
          end

          it "raises an error if 'with' follows 'and_return'" do
            lambda{ klass.any_instance.stub(:foo).and_return(1).with("1") }.should raise_error(NoMethodError)
          end

          it "raises an error if 'with' follows 'and_raise'" do
            lambda{ klass.any_instance.stub(:foo).and_raise(1).with("1") }.should raise_error(NoMethodError)
          end

          it "raises an error if 'with' follows 'and_yield'" do
            lambda{ klass.any_instance.stub(:foo).and_yield(1).with("1") }.should raise_error(NoMethodError)
          end
        end

        context "#should_receive" do
          it "raises an error if 'should_receive' follows 'with'" do
            lambda{ klass.any_instance.with("1").should_receive(:foo) }.should raise_error(NoMethodError)
          end

          it "raises an error if 'with' follows 'and_return'" do
            pending "see Github issue #42"
            lambda{ klass.any_instance.should_receive(:foo).and_return(1).with("1") }.should raise_error(NoMethodError)
          end

          it "raises an error if 'with' follows 'and_raise'" do
            pending "see Github issue #42"
            lambda{ klass.any_instance.should_receive(:foo).and_raise(1).with("1") }.should raise_error(NoMethodError)
          end
        end
      end

      context "with #stub" do
        it "does not suppress an exception when a method that doesn't exist is invoked" do
          klass.any_instance.stub(:foo)
          lambda{ klass.new.bar }.should raise_error(NoMethodError)
        end

        context "with #and_return" do
          it "stubs a method that doesn't exist" do
            klass.any_instance.stub(:foo).and_return(1)
            klass.new.foo.should eq(1)
          end

          it "stubs a method that exists" do
            klass.any_instance.stub(:existing_method).and_return(1)
            klass.new.existing_method.should eq(1)
          end

          it "returns the same object for calls on different instances" do
            return_value = Object.new
            klass.any_instance.stub(:foo).and_return(return_value)
            klass.new.foo.should be(return_value)
            klass.new.foo.should be(return_value)
          end
        end

        context "with #and_yield" do
          it "yields the value specified" do
            yielded_value = Object.new
            klass.any_instance.stub(:foo).and_yield(yielded_value)
            klass.new.foo{|value| value.should be(yielded_value)}
          end
        end

        context "with #and_raise" do
          it "stubs a method that doesn't exist" do
            klass.any_instance.stub(:foo).and_raise(CustomErrorForAnyInstanceSpec)
            lambda{ klass.new.foo}.should raise_error(CustomErrorForAnyInstanceSpec)
          end

          it "stubs a method that exists" do
            klass.any_instance.stub(:existing_method).and_raise(CustomErrorForAnyInstanceSpec)
            lambda{ klass.new.existing_method}.should raise_error(CustomErrorForAnyInstanceSpec)
          end
        end

        context "with a block" do
          it "stubs a method" do
            klass.any_instance.stub(:foo) { 1 }
            klass.new.foo.should eq(1)
          end

          it "returns the same computed value for calls on different instances" do
            klass.any_instance.stub(:foo) { 1 + 2 }
            klass.new.foo.should eq(klass.new.foo)
          end
        end

        context "core ruby objects" do
          it "works uniformly across *everything*" do
            Object.any_instance.stub(:foo).and_return(1)
            Object.new.foo.should eq(1)
          end

          it "works with the non-standard constructor []" do
            Array.any_instance.stub(:foo).and_return(1)
            [].foo.should eq(1)
          end

          it "works with the non-standard constructor {}" do
            Hash.any_instance.stub(:foo).and_return(1)
            {}.foo.should eq(1)
          end

          it "works with the non-standard constructor \"\"" do
            String.any_instance.stub(:foo).and_return(1)
            "".foo.should eq(1)
          end

          it "works with the non-standard constructor \'\'" do
            String.any_instance.stub(:foo).and_return(1)
            ''.foo.should eq(1)
          end

          it "works with the non-standard constructor module" do
            Module.any_instance.stub(:foo).and_return(1)
            module RSpec::SampleRspecTestModule;end
            RSpec::SampleRspecTestModule.foo.should eq(1)
          end

          it "works with the non-standard constructor class" do
            Class.any_instance.stub(:foo).and_return(1)
            class RSpec::SampleRspecTestClass;end
            RSpec::SampleRspecTestClass.foo.should eq(1)
          end
        end
      end

      context "with #should_receive" do
        context "when an expectation is set on a method does not exist" do
          it "returns the expected value" do
            klass.any_instance.should_receive(:foo).and_return(1)
            klass.new.foo(1).should eq(1)
          end

          it "fails if an instance is created but no invocation occurs" do
            expect do
              klass.any_instance.should_receive(:foo)
              instance = klass.new
              instance.rspec_verify
            end.to raise_error(RSpec::Mocks::MockExpectationError)
          end

          it "fails if no instance is created" do
            expect do
              klass.any_instance.should_receive(:foo).and_return(1)
              klass.rspec_verify
            end.to raise_error(RSpec::Mocks::MockExpectationError)
          end
        end

        context "when an expectation is set on a method that exists" do
          it "returns the expected value" do
            klass.any_instance.should_receive(:existing_method).and_return(1)
            klass.new.existing_method(1).should eq(1)
          end

          it "fails if an instance is created but no invocation occurs" do
            expect do
              klass.any_instance.should_receive(:existing_method)
              instance = klass.new
              instance.rspec_verify
            end.to raise_error(RSpec::Mocks::MockExpectationError)
          end

          it "fails if no instance is created" do
            expect do
              klass.any_instance.should_receive(:existing_method).and_return(1)
              klass.rspec_verify
            end.to raise_error(RSpec::Mocks::MockExpectationError)
          end
        end

        context "resetting" do
          it "does not interfere with expectations set on the class" do
            expect do
              klass.should_receive(:woot).and_return(3)
              klass.rspec_verify
            end.to raise_error(RSpec::Mocks::MockExpectationError)
          end
        end

        context "message count" do
          context "the 'once' constraint" do
            it "passes for one invocation" do
              klass.any_instance.should_receive(:foo).once
              instance = klass.new
              instance.foo
            end

            it "fails when no instances are declared" do
              expect do
                klass.any_instance.should_receive(:foo).once
                klass.new.rspec_verify
              end.to raise_error(RSpec::Mocks::MockExpectationError)
            end

            it "fails when an instance is declared but there are no invocations" do
              expect do
                klass.any_instance.should_receive(:foo).once
                instance = klass.new
                klass.new.rspec_verify
              end.to raise_error(RSpec::Mocks::MockExpectationError)
            end

            it "fails for more than one invocation" do
              expect do
                klass.any_instance.should_receive(:foo).once
                instance = klass.new
                2.times { instance.foo }
                instance.rspec_verify
              end.to raise_error(RSpec::Mocks::MockExpectationError)
            end
          end

          context "the 'twice' constraint" do
            it "passes for two invocations" do
              klass.any_instance.should_receive(:foo).twice
              instance = klass.new
              2.times { instance.foo }
            end

            it "fails for more than two invocations" do
              expect do
                klass.any_instance.should_receive(:foo).twice
                instance = klass.new
                3.times { instance.foo }
                instance.rspec_verify
              end.to raise_error(RSpec::Mocks::MockExpectationError)
            end
          end

          context "the 'exactly(n)' constraint" do
            it "passes for n invocations where n = 3" do
              klass.any_instance.should_receive(:foo).exactly(3).times
              instance = klass.new
              3.times { instance.foo }
            end

            it "fails for n invocations where n < 3" do
              expect do
                klass.any_instance.should_receive(:foo).exactly(3).times
                instance = klass.new
                2.times { instance.foo }
                instance.rspec_verify
              end.to raise_error(RSpec::Mocks::MockExpectationError)
            end

            it "fails for n invocations where n > 3" do
              expect do
                klass.any_instance.should_receive(:foo).exactly(3).times
                instance = klass.new
                4.times { instance.foo }
                instance.rspec_verify
              end.to raise_error(RSpec::Mocks::MockExpectationError)
            end
          end

          context "the 'at_least(n)' constraint" do
            it "passes for n invocations where n = 3" do
              klass.any_instance.should_receive(:foo).at_least(3).times
              instance = klass.new
              3.times { instance.foo }
            end

            it "fails for n invocations where n < 3" do
              expect do
                klass.any_instance.should_receive(:foo).at_least(3).times
                instance = klass.new
                2.times { instance.foo }
                instance.rspec_verify
              end.to raise_error(RSpec::Mocks::MockExpectationError)
            end

            it "passes for n invocations where n > 3" do
              klass.any_instance.should_receive(:foo).at_least(3).times
              instance = klass.new
              4.times { instance.foo }
            end
          end

          context "the 'at_most(n)' constraint" do
            it "passes for n invocations where n = 3" do
              klass.any_instance.should_receive(:foo).at_most(3).times
              instance = klass.new
              3.times { instance.foo }
            end

            it "passes for n invocations where n < 3" do
              klass.any_instance.should_receive(:foo).at_most(3).times
              instance = klass.new
              2.times { instance.foo }
            end

            it "fails for n invocations where n > 3" do
              expect do
                klass.any_instance.should_receive(:foo).at_most(3).times
                instance = klass.new
                4.times { instance.foo }
                instance.rspec_verify
              end.to raise_error(RSpec::Mocks::MockExpectationError)
            end
          end

          context "the 'never' constraint" do
            it "passes for 0 invocations" do
              klass.any_instance.should_receive(:foo).never
              instance = klass.new
              instance.rspec_verify
            end

            it "fails on the first invocation" do
              expect do
                klass.any_instance.should_receive(:foo).never
                klass.new.foo
              end.to raise_error(RSpec::Mocks::MockExpectationError)
            end
          end

          context "the 'any_number_of_times' constraint" do
            it "passes for 0 invocations" do
              klass.any_instance.should_receive(:foo).any_number_of_times
              klass.new.rspec_verify
            end

            it "passes for a non-zero number of invocations" do
              klass.any_instance.should_receive(:foo).any_number_of_times
              instance = klass.new
              instance.foo
              instance.rspec_verify
            end
          end
        end
      end

      context "when resetting after an example" do
        it "restores the class to its original state after each example" do
          space = RSpec::Mocks::Space.new
          space.add(klass)

          klass.any_instance.stub(:existing_method).and_return(1)
          klass.method_defined?(:__existing_method_without_any_instance__).should be_true
          
          space.reset_all
          
          klass.method_defined?(:__existing_method_without_any_instance__).should be_false
          klass.new.existing_method.should eq(2)
        end

        it "adds an class to the current space when #any_instance is invoked" do
          klass.any_instance
          RSpec::Mocks::space.send(:mocks).should include(klass)
        end

        it "adds an instance to the current space when stubbed method is invoked" do
          klass.any_instance.stub(:foo)
          instance = klass.new
          instance.foo
          RSpec::Mocks::space.send(:mocks).should include(instance)
        end
      end
    end
  end
end
