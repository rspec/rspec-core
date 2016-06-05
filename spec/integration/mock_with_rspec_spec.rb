require 'support/aruba_support'

# RSpec uses its own mocking framework by default. You can also configure it
# explicitly if you wish.

RSpec.describe 'mock with rspec', :ui do
  include_context "aruba support"

  describe "Passing message expectation" do
    context 'with a passing example using doubles' do
      before do
        write_file 'example_spec.rb', <<-EOF
          RSpec.configure do |config|
            config.mock_with :rspec
          end

          RSpec.describe "mocking with RSpec" do
            it "passes when it should" do
              receiver = double('receiver')
              expect(receiver).to receive(:message)
              receiver.message
            end
          end
       EOF
      end

      after { remove_file 'example_spec.rb' }

      context "when `rspec example_spec.rb` is run" do
        it "passes" do
          run_command 'example_spec.rb'
          expect(stdout.string).to match(/0 failures/)
          expect(stdout.string).to_not match(/0 examples/)
        end
      end
    end
  end

  describe "Failing message expectation" do
    context 'with a failing example using doubles' do
      before do
        write_file 'example_spec.rb', <<-EOF
          RSpec.configure do |config|
            config.mock_with :rspec
          end

          RSpec.describe "mocking with RSpec" do
            it "fails when it should" do
              receiver = double('receiver')
              expect(receiver).to receive(:message)
            end
          end
        EOF
      end

      after { remove_file 'example_spec.rb' }

      context "when `rspec example_spec.rb` is run" do
        it "fails" do
          run_command 'example_spec.rb'
          expect(stdout.string).to match(/1 failure/)
          expect(stdout.string).to match(/1 example/)
        end
      end
    end
  end

  describe "Failing message expectation in pending example (remains pending)" do
    context 'with a pending example"' do
      before do
        write_file 'example_spec.rb', <<-EOF
          RSpec.configure do |config|
            config.mock_with :rspec
          end

          RSpec.describe "failed message expectation in a pending example" do
            it "is listed as pending" do
              pending
              receiver = double('receiver')
              expect(receiver).to receive(:message)
            end
          end
        EOF
      end

      after { remove_file 'example_spec.rb' }

      context "when `rspec example_spec.rb` is run" do
        it "passes with pending example" do
          run_command 'example_spec.rb'
          expect(stdout.string).to match(/0 failures/)
          expect(stdout.string).to match(/1 pending/)
          expect(stdout.string).to_not match(/1 examples/)
        end
      end
    end
  end

  describe "Passing message expectation in pending example (fails)" do
    context 'with a failing pending example' do
      before do
        write_file 'example_spec.rb', <<-EOF
          RSpec.configure do |config|
            config.mock_with :rspec
          end

          RSpec.describe "passing message expectation in a pending example" do
            it "fails with FIXED" do
              pending
              receiver = double('receiver')
              expect(receiver).to receive(:message)
              receiver.message
            end
          end
        EOF
      end

      after { remove_file 'example_spec.rb' }

      context "when `rspec example_spec.rb` is run" do
        it "fails" do
          run_command 'example_spec.rb'
          expect(stdout.string).to match(/FIXED/)
          expect(stdout.string).to match(/1 failure/)
          expect(stdout.string).to_not match(/1 examples/)
        end
      end
    end
  end

  describe "Accessing `RSpec.configuration.mock_framework.framework_name`" do
    context 'with an example expecting the mock framework to be RSpec"' do
      before do
        write_file 'example_spec.rb', <<-EOF
          RSpec.configure do |config|
            config.mock_with :rspec
          end

          RSpec.describe "RSpec.configuration.mock_framework.framework_name" do
            it "returns :rspec" do
              expect(RSpec.configuration.mock_framework.framework_name).to eq(:rspec)
            end
          end
        EOF
      end

      after { remove_file 'example_spec.rb' }

      context "when `rspec example_spec.rb` is run" do
        it "passes" do
          run_command 'example_spec.rb'
          expect(stdout.string).to match(/0 failures/)
          expect(stdout.string).to_not match(/0 examples/)
        end
      end
    end
  end

  describe "Doubles may be used in generated descriptions" do
    context 'with an example lacking a description' do
      before do
        write_file 'example_spec.rb', <<-EOF
          RSpec.configure do |config|
            config.mock_with :rspec
          end

          RSpec.describe "Testing" do
            # Examples with no descriptions will default to RSpec-generated descriptions
            it do
              foo = double("Test")
              expect(foo).to be foo
            end
          end
        EOF
      end

      after { remove_file 'example_spec.rb' }

      context "when `rspec example_spec.rb` is run" do
        it "passes" do
          run_command 'example_spec.rb'
          expect(stdout.string).to match(/0 failures/)
          expect(stdout.string).to_not match(/0 examples/)
        end
      end
    end
  end
end
