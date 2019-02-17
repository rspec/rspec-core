require 'tmpdir'
require 'rspec/support/spec/in_sub_process'

module RSpec
  module Core
    RSpec.describe DidYouMean do
      describe 'Call to DidYouMean' do
        context 'Exception is not a LoadError' do
          let(:exception) { RuntimeError.new }
          it 'should return nil' do
            expect(DidYouMean.new('spec1', exception).call).to eq nil
          end
        end
        context 'Exception is a LoadError' do
          let(:exception) { LoadError.new }
          describe 'Success' do
            it 'should return a useful suggestion' do
              name = './spec/rspec/core/did_you_mean_spec.rb'
              expect(DidYouMean.new(name[0..-2], exception).call).to include name
            end
            context 'numerous possibilities' do
              it 'should only return a small number of suggestions' do
                name = './spec/rspec/core/drb_spec.r'
                suggestions = DidYouMean.new(name, exception).call
                expect(suggestions.split("\n").size).to eq 4
              end
            end
          end
          context 'No suitable suggestions' do
            it 'Whereof one cannot speak, thereof one must be silent' do
              name = './' + 'x' * 50
              expect(DidYouMean.new(name, exception).call).to be nil
            end
          end
        end
      end
      describe 'Key private methods' do
        let(:str1) { 'canonical' }
        describe 'levenshtein_distance' do
          it{ expect(DidYouMean.new(str1).send(:levenshtein_distance, str1, test_h[:empty])).to eq 9 }
          it{ expect(DidYouMean.new(str1).send(:levenshtein_distance, str1, test_h[:identical])).to eq 0 }
          it{ expect(DidYouMean.new(str1).send(:levenshtein_distance, str1, test_h[:two_insertions])).to eq 2 }
          it{ expect(DidYouMean.new(str1).send(:levenshtein_distance, str1, test_h[:two_insertions_deletion])).to eq 3 }
          it{ expect(DidYouMean.new(str1).send(:levenshtein_distance, str1, test_h[:insertion_substitution_deletion])).to eq 3 }
          context 'UTF-8' do
            let(:str1) { '變形金剛4:絕跡重生' }
            it{ expect(DidYouMean.new(str1).send(:levenshtein_distance, str1,
              '變形金剛4: 絕跡重生')).to eq 1 }
          end
        end
        describe 'proximity' do
          it{ expect(DidYouMean.new(str1).send(:proximity, str1, test_h[:two_insertions])).to eq 0.2 }
        end
      end

      private
      def test_h
        {
          empty: '',
          identical: 'canonical',
          two_insertions: 'canonixxcal',
          two_insertions_deletion: 'anonixxcal',
          insertion_substitution_deletion: 'fnaonical'
        }
      end
    end
  end
end
