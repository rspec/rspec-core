require 'tmpdir'
require 'rspec/support/spec/in_sub_process'

module RSpec
  module Core
    RSpec.describe DidYouMean do
      if defined?(::DidYouMean::SpellChecker)
        describe 'Call to DidYouMean' do
          describe 'Success' do
            let(:name) { './spec/rspec/core/did_you_mean_spec.rb' }
            it 'should return a useful suggestion' do
              expect(DidYouMean.new(name[0..-2]).call).to include name
            end
            context 'numerous possibilities' do
              it 'should only return a small number of suggestions' do
                name = './spec/rspec/core/drb_spec.r'
                suggestions = DidYouMean.new(name).call
                expect(suggestions.split("\n").size).to eq 2
              end
            end
          end
          context 'No suitable suggestions' do
            it 'Whereof one cannot speak, thereof one must be silent' do
              name = './' + 'x' * 50
              expect(DidYouMean.new(name).call).to be nil
            end
          end
        end
      else # ruby 2.3.2 or less
        describe 'Call to DidYouMean' do
          describe 'Success' do
            let(:name) { './spec/rspec/core/did_you_mean_spec.rb' }
            it 'should return no suggestion' do
              expect(DidYouMean.new(name[0..-2]).call).to eq nil
            end
          end
        end
      end
    end
  end
end
