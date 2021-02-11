module RSpec
  module Core
    class Example
      RSpec.describe ExecutionResult do
        it 'has `status` and `pending_message` attributes' do
          expect(ExecutionResult.new).to have_attributes(
            :status => nil,
            :pending_message => nil
          )
        end

        it 'provides a `pending_fixed?` predicate' do
          er = ExecutionResult.new
          expect { er.pending_fixed = true }.to change(er, :pending_fixed?).from(false).to(true)
        end

        it 'does not support `to_h`' do
          expect(ExecutionResult.new.respond_to?(:to_h)).to be false
        end

        it 'does not behave like a hash' do
          expect(ExecutionResult.new.respond_to?(:[])).to be false
        end
      end
    end
  end
end
