require 'spec_helper'

RSpec.describe "an example" do
  matcher :be_pending_with do |message|
    match do |example|
      example.pending? && example.metadata[:execution_result][:pending_message] == message
    end

    failure_message_for_should do |example|
      "expected: example pending with #{message.inspect}\n     got: #{example.metadata[:execution_result][:pending_message].inspect}"
    end
  end

  matcher :be_skipped_with do |message|
    match do |example|
      example.skipped? && example.metadata[:execution_result][:pending_message] == message
    end

    failure_message_for_should do |example|
      "expected: example skipped with #{message.inspect}\n     got: #{example.metadata[:execution_result][:pending_message].inspect}"
    end
  end

  context "declared pending with metadata" do
    it "uses the value assigned to :pending as the message" do
      group = RSpec::Core::ExampleGroup.describe('group') do
        example "example", :pending => 'just because' do
          fail
        end
      end
      example = group.examples.first
      example.run(group.new, double.as_null_object)
      expect(example).to be_pending_with('just because')
    end

    it "sets the message to 'No reason given' if :pending => true" do
      group = RSpec::Core::ExampleGroup.describe('group') do
        example "example", :pending => true do
          fail
        end
      end
      example = group.examples.first
      example.run(group.new, double.as_null_object)
      expect(example).to be_pending_with('No reason given')
    end
  end

  context "with no block" do
    it "is listed as pending with 'Not yet implemented'" do
      group = RSpec::Core::ExampleGroup.describe('group') do
        it "has no block"
      end
      example = group.examples.first
      example.run(group.new, double.as_null_object)
      expect(example).to be_skipped_with('Not yet implemented')
    end
  end

  context "with no args" do
    it "is listed as pending with the default message" do
      group = RSpec::Core::ExampleGroup.describe('group') do
        it "does something" do
          pending
          fail
        end
      end
      example = group.examples.first
      example.run(group.new, double.as_null_object)
      expect(example).to be_pending_with(RSpec::Core::Pending::NO_REASON_GIVEN)
    end

    it "fails when the rest of the example passes" do
      called = false
      group = RSpec::Core::ExampleGroup.describe('group') do
        it "does something" do
          pending
          called = true
        end
      end

      example = group.examples.first
      example.run(group.new, double.as_null_object)
      expect(called).to eq(true)
      result = example.metadata[:execution_result]
      expect(result[:pending_fixed]).to eq(true)
      expect(result[:status]).to eq("failed")
    end
  end

  context "with no docstring" do
    context "declared with the pending method" do
      it "does not have an auto-generated description" do
        group = RSpec::Core::ExampleGroup.describe('group') do
          it "checks something" do
            expect((3+4)).to eq(7)
          end
          pending do
            expect("string".reverse).to eq("gnirts")
          end
        end
        example = group.examples.last
        example.run(group.new, double.as_null_object)
        expect(example.description).to match(/example at/)
      end
    end

    context "after another example with some assertion" do
      it "does not show any message" do
        group = RSpec::Core::ExampleGroup.describe('group') do
          it "checks something" do
            expect((3+4)).to eq(7)
          end
          specify do
            pending
          end
        end
        example = group.examples.last
        example.run(group.new, double.as_null_object)
        expect(example.description).to match(/example at/)
      end
    end
  end

  context "with a message" do
    it "is listed as pending with the supplied message" do
      group = RSpec::Core::ExampleGroup.describe('group') do
        it "does something" do
          pending("just because")
        end
      end
      example = group.examples.first
      example.run(group.new, double.as_null_object)
      expect(example).to be_pending_with('just because')
    end
  end

  context "with a block" do
    def run_example(*pending_args, &block)
      group = RSpec::Core::ExampleGroup.describe('group') do
        it "does something" do
          pending(*pending_args) { block.call if block }
        end
      end
      example = group.examples.first
      example.run(group.new, double.as_null_object)
      example
    end

    context "that fails" do
      def run_example(*pending_args)
        super(*pending_args) { raise ArgumentError.new }
      end

      context "when given no options" do
        it "is listed as pending with the supplied message" do
          expect(run_example("just because")).to be_pending_with("just because")
        end

        it "is listed as pending with the default message when no message is given" do
          expect(run_example).to be_pending_with(RSpec::Core::Pending::NO_REASON_GIVEN)
        end
      end

      context "when given a truthy :if option" do
        it "is listed as pending with the supplied message" do
          expect(run_example("just because", :if => true)).to be_pending_with("just because")
        end

        it "is listed as pending with the default message when no message is given" do
          expect(run_example(:if => true)).to be_pending_with(RSpec::Core::Pending::NO_REASON_GIVEN)
        end
      end

      context "when given a falsey :if option" do
        it "runs the example and fails" do
          expect(run_example(                :if => false)).to fail_with(ArgumentError)
          expect(run_example("just because", :if => false)).to fail_with(ArgumentError)
        end
      end

      context "when given a truthy :unless option" do
        it "runs the example and fails" do
          expect(run_example(                :unless => true)).to fail_with(ArgumentError)
          expect(run_example("just because", :unless => true)).to fail_with(ArgumentError)
        end
      end

      context "when given a falsey :unless option" do
        it "is listed as pending with the supplied message" do
          expect(run_example("just because", :unless => false)).to be_pending_with("just because")
        end

        it "is listed as pending with the default message when no message is given" do
          expect(run_example(:unless => false)).to be_pending_with(RSpec::Core::Pending::NO_REASON_GIVEN)
        end
      end
    end

    context "that fails due to a failed message expectation" do
      def run_example(*pending_args)
        super(*pending_args) { expect("foo").to receive(:bar) }
      end

      it "passes" do
        expect(run_example.exception).to be_nil
      end

      it 'indicates it is pending with the given message' do
        expect(run_example("just because")).to be_pending_with("just because")
      end

      it 'indicates the pending block was not fixed' do
        expect(run_example.metadata[:execution_result][:pending_fixed]).to be false
      end
    end

    context 'that fails due to both a failed message expectation and a standard failure' do
      def run_example(*pending_args)
        super(*pending_args) {
          expect("foo").to receive("bar")
          fail
        }
      end

      it 'indicates it is pending with the given message' do
        expect(run_example("just because")).to be_pending_with("just because")
      end

      it 'indicates the pending block was not fixed' do
        expect(run_example.metadata[:execution_result][:pending_fixed]).to be false
      end
    end

    it 'does not verify or teardown mocks multiple times' do
      counts = Hash.new(0)

      RSpec::Core::ExampleGroup.describe('group') do
        define_method(:verify_mocks_for_rspec)   { counts[:verify]   += 1; super() }
        define_method(:teardown_mocks_for_rspec) { counts[:teardown] += 1; super() }
        example { pending { } }
      end.run

      expect(counts).to eq(:verify => 1, :teardown => 1)
    end

    context "that passes" do
      def run_example(*pending_args)
        super(*pending_args) { expect(3).to eq(3) }
      end

      context "when given no options" do
        it "fails with a PendingExampleFixedError" do
          expect(run_example("just because")).to fail_with(RSpec::Core::Pending::PendingExampleFixedError)
          expect(run_example).to                 fail_with(RSpec::Core::Pending::PendingExampleFixedError)
        end
      end

      context "when given a truthy :if option" do
        it "fails with a PendingExampleFixedError" do
          expect(run_example("just because", :if => true)).to fail_with(RSpec::Core::Pending::PendingExampleFixedError)
          expect(run_example(                :if => true)).to fail_with(RSpec::Core::Pending::PendingExampleFixedError)
        end
      end

      context "when given a falsey :if option" do
        it "runs the example and it passes" do
          expect(run_example(                :if => false)).to pass
          expect(run_example("just because", :if => false)).to pass
        end
      end

      context "when given a truthy :unless option" do
        it "runs the example and it passes" do
          expect(run_example(                :unless => true)).to pass
          expect(run_example("just because", :unless => true)).to pass
        end
      end

      context "when given a falsey :unless option" do
        it "fails with a PendingExampleFixedError" do
          expect(run_example("just because", :unless => false)).to fail_with(RSpec::Core::Pending::PendingExampleFixedError)
          expect(run_example(                :unless => false)).to fail_with(RSpec::Core::Pending::PendingExampleFixedError)
        end
      end
    end
  end
end
