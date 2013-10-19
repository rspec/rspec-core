require "spec_helper"

module RSpec
  module Core
    module Ordering
      describe Identity do
        it "does not affect the ordering of the items" do
          expect(Identity.new.order([1, 2, 3])).to eq([1, 2, 3])
        end
      end

      describe Random do
        describe '.order' do
          subject { described_class.new(configuration) }

          let(:configuration)  { RSpec::Core::Configuration.new }
          let(:items)          { 10.times.map { |n| n } }
          let(:shuffled_items) { subject.order items }

          it 'shuffles the items randomly' do
            expect(shuffled_items).to match_array items
            expect(shuffled_items).to_not eq items
          end

          context 'given multiple calls' do
            it 'returns the items in the same order' do
              expect(subject.order(items)).to eq shuffled_items
            end
          end
        end
      end

      describe Custom do
        it 'uses the block to order the list' do
          strategy = Custom.new(proc { |list| list.reverse })

          expect(strategy.order([1, 2, 3, 4])).to eq([4, 3, 2, 1])
        end
      end

      describe Registry do
        let(:configuration) { Configuration.new }
        subject(:registry) { Registry.new(configuration) }

        describe "#fetch" do
          it "gives the registered ordering when called with a symbol" do
            ordering = Object.new
            subject.register(:falcon, ordering)

            expect(subject.fetch(:falcon)).to be ordering
          end

          context "when given an unrecognized symbol" do
            it 'invokes the given block and returns its value' do
              expect(subject.fetch(:falcon) { :fallback }).to eq(:fallback)
            end

            it 'raises an error if no block is given' do
              expect {
                subject.fetch(:falcon)
              }.to raise_error(IndexError)
            end
          end
        end
      end
    end
  end
end
