require 'tmpdir'
require 'rspec/support/spec/in_sub_process'

module RSpec
  module Core
    module DidYouMean
      RSpec.describe Suggestions do
        context 'Exception is not a LoadError' do
          let(:exception) { RuntimeError.new }
          it 'should return nil' do
            expect(DidYouMean::Suggestions.new('spec1', exception).call).to eq nil
          end
        end
        context 'Exception is a LoadError' do
          let(:exception) { LoadError.new }
          describe 'Success' do
            it 'should return a useful suggestion' do
              name = './spec/rspec/core/did_you_mean/suggestions_spec.rb'
              expect(DidYouMean::Suggestions.new(name[0..-2], exception).call).to include name
            end
            context 'numerous possibilities' do
              it 'should only return a small number of suggestions' do
                name = './spec/rspec/core/drb_spec.r'
                suggestions = DidYouMean::Suggestions.new(name, exception).call
                expect(suggestions.split("\n").size).to eq 4
              end
            end
          end
          context 'No suitable suggestions' do
            it 'Whereof one cannot speak, thereof one must be silent' do
              name = './' + 'x' * 50
              expect(DidYouMean::Suggestions.new(name, exception).call).to be nil
            end
          end
        end
      end
    end
  end
end
