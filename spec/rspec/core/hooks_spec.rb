require "spec_helper"

module RSpec::Core
  describe Hooks do
    class HooksHost
      include Hooks
    end

    [:before, :after, :around].each do |type|
      [:each, :all].each do |scope|
        next if type == :around && scope == :all

        describe "##{type}(#{scope})" do
          it_behaves_like "metadata hash builder" do
            define_method :metadata_hash do |*args|
              instance = HooksHost.new
              args.unshift scope if scope
              hooks = instance.send(type, *args) {}
              hooks.first.options
            end
          end
        end
      end

      [true, false].each do |config_value|
        context "when RSpec.configuration.treat_symbols_as_metadata_keys_with_true_values is set to #{config_value}" do
          before(:each) do
            Kernel.stub(:warn)
            RSpec.configure { |c| c.treat_symbols_as_metadata_keys_with_true_values = config_value }
          end

          describe "##{type}(no scope)" do
            let(:instance) { HooksHost.new }

            it "defaults to :each scope if no arguments are given" do
              hooks = instance.send(type) {}
              hook = hooks.first
              instance.hooks[type][:each].should include(hook)
            end

            it "defaults to :each scope if the only argument is a metadata hash" do
              hooks = instance.send(type, :foo => :bar) {}
              hook = hooks.first
              instance.hooks[type][:each].should include(hook)
            end

            it "raises an error if only metadata symbols are given as arguments" do
              expect { instance.send(type, :foo, :bar) {} }.to raise_error(ArgumentError)
            end
          end
        end
      end
    end

    [:before, :after].each do |type|
      [:each, :all, :suite].each do |scope|
        [true, false].each do |config_value|
          context "when RSpec.configuration.treat_symbols_as_metadata_keys_with_true_values is set to #{config_value}" do
            before(:each) do
              RSpec.configure { |c| c.treat_symbols_as_metadata_keys_with_true_values = config_value }
            end

            describe "##{type}(#{scope.inspect})" do
              let(:instance) { HooksHost.new }
              let!(:hook) do
                hooks = instance.send(type, scope) {}
                hooks.first
              end

              it "does not make #{scope.inspect} a metadata key" do
                hook.options.should be_empty
              end

              it "is scoped to #{scope.inspect}" do
                instance.hooks[type][scope].should include(hook)
              end
            end
          end
        end
      end
    end

    describe "#around" do
      context "when not running the example within the around block" do
        it "does not run the example" do
          examples = []
          group = ExampleGroup.describe do
            around do |example|
            end
            it "foo" do
              examples << self
            end
          end
          group.run
          examples.should have(0).example
        end
      end

      context "when running the example within the around block" do
        it "runs the example" do
          examples = []
          group = ExampleGroup.describe do
            around do |example|
              example.run
            end
            it "foo" do
              examples << self
            end
          end
          group.run
          examples.should have(1).example
        end
      end

      context "when running the example within a block passed to a method" do
        it "runs the example" do
          examples = []
          group = ExampleGroup.describe do
            def yielder
              yield
            end

            around do |example|
              yielder { example.run }
            end
            it "foo" do
              examples << self
            end
          end
          group.run
          examples.should have(1).example
        end
      end

      describe Hooks::Hook do
        it "requires a block" do
          lambda {
            Hooks::BeforeHook.new :foo => :bar
          }.should raise_error("no block given for before hook")
        end
      end
    end

    describe "prepend_before" do
      it "should prepend before callbacks so they are run prior to other before filters for the specified scope" do
        fiddle = []
        example_group = ExampleGroup.describe do
          around do |example|
            example.run
          end
          it "foo" do
            examples << self
          end
        end
        example_group.prepend_before(:all) { fiddle << "prepend_before(:all)" }
        example_group.before(:all) { fiddle << "before(:all)" }
        example_group.prepend_before(:each) { fiddle << "prepend_before(:each)" }
        example_group.before(:each) { fiddle << "before(:each)" }
        RSpec.configure { |config| config.prepend_before(:each) { fiddle << "config.prepend_before(:each)" } }
        RSpec.configure { |config| config.prepend_before(:all) { fiddle << "config.prepend_before(:all)" } }
        example_group.run
        fiddle.should == [
            'config.prepend_before(:all)',
            'prepend_before(:all)',
            'before(:all)',
            "config.prepend_before(:each)",
            'prepend_before(:each)',
            'before(:each)'
        ]
      end
    end

    describe "#append_before" do

      it "should order before callbacks from global to local" do
        order = []
        example_group = ExampleGroup.describe do
          around do |example|
            example.run
          end
          it "foo" do
            examples << self
          end
        end
        example_group.append_before(:each) do
          order << :example_group_append_before_each
        end
        RSpec.configure { |config| config.append_before { order << :append_before_each } } # default is :each
        RSpec.configure { |config| config.append_before(:all) { order << :append_before_all } }
        RSpec.configure { |config| config.before(:all) { order << :before_all } }

        example_group.append_before(:all) do
          order << :example_group_append_before_all
        end

        example_group.run
        order.should == [
            :append_before_all,
            :before_all,
            :example_group_append_before_all,
            :append_before_each,
            :example_group_append_before_each,
        ]
      end
    end

    describe "#prepend_after" do

      it "should order after callbacks from global to local" do
        order = []
        example_group = ExampleGroup.describe do
          around do |example|
            example.run
          end
          it "foo" do
            examples << self
          end
        end

        RSpec.configure { |config| config.prepend_after(:all) { order << :prepend__after_all } }
        RSpec.configure { |config| config.prepend_after(:each) { order << :prepend__after_each } }
        example_group.prepend_after(:all) do
          order << :example_group_prepend_after_all
        end
        example_group.prepend_after(:each) do
          order << :example_group_prepend_after_each
        end
        example_group.run
        order.should == [
            :example_group_prepend_after_each,
            :prepend__after_each,
            :example_group_prepend_after_all,
            :prepend__after_all
        ]
      end
    end

    describe "#append_after" do

      it "should append callbacks so they are run after other after filters for the specified scope" do
        order = []
        example_group = ExampleGroup.describe do
          around do |example|
            example.run
          end
          it "foo" do
            examples << self
          end
        end

        RSpec.configure { |config| config.append_after(:all) { order << :append__after_all } }
        RSpec.configure { |config| config.after(:all) { order << :after_all } }
        example_group.append_after(:all) do
          order << :example_group_append__after_all
        end

        RSpec.configure { |config| config.append_after(:each) { order << :append_after_each } }

        example_group.append_after(:each) do
          order << :example_group_append__after_each
        end

        example_group.after(:each) do
          order << :example_group__after_each
        end

        example_group.run
        order.should == [
            :example_group__after_each,
            :example_group_append__after_each,
            :append_after_each,
            :example_group_append__after_all,
            :after_all,
            :append__after_all
        ]
      end

    end
  end
end
