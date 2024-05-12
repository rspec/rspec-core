require 'support/aruba_support'

RSpec.describe 'Failed spec rerun location' do

  include_context "aruba support"

  before do
    setup_aruba
    write_file "some_examples.rb", "
      RSpec.shared_examples_for 'a failing spec' do
          it 'fails' do
              expect(1).to eq(2)
          end
      end
    "

    file = cd('.') { "#{Dir.pwd}/some_examples.rb" }
    load file

    write_file "local_shared_examples_spec.rb", "
      RSpec.describe do
          shared_examples_for 'a failing spec' do
              it 'fails' do
                  expect(1).to eq(2)
              end
          end

          context 'the first context' do
              it_behaves_like 'a failing spec'
          end

          context 'the second context' do
              it_behaves_like 'a failing spec'
          end
      end
    "

    write_file "non_local_shared_examples_spec.rb", "
        RSpec.describe do
            context 'the first context' do
                it_behaves_like 'a failing spec'
            end

            context 'the second context' do
                it_behaves_like 'a failing spec'
            end
        end
    "
  end

  context "when config.location_rerun_uses_line_number is set to false" do
    it 'prints the example id of the failed assertion' do
      run_command("#{Dir.pwd}/tmp/aruba/local_shared_examples_spec.rb")

      expect(last_cmd_stdout).to include(<<-MSG
Failed examples:

rspec './local_shared_examples_spec.rb[1:1:1:1]' #  the first context behaves like a failing spec fails
rspec './local_shared_examples_spec.rb[1:2:1:1]' #  the second context behaves like a failing spec fails
      MSG
      )
    end
    context "and the shared examples are defined in a separate file" do
      it 'prints the line number where the `it_behaves_like` was called in the local file' do
        run_command("#{Dir.pwd}/tmp/aruba/non_local_shared_examples_spec.rb")

        expect(last_cmd_stdout).to include(<<-MSG
Failed examples:

rspec ./non_local_shared_examples_spec.rb:4 #  the first context behaves like a failing spec fails
rspec ./non_local_shared_examples_spec.rb:8 #  the second context behaves like a failing spec fails
        MSG
        )
      end
    end
  end

  context "when config.location_rerun_uses_line_number is set to true" do
    before do
      allow(RSpec.configuration).to receive(:location_rerun_uses_line_number).and_return(true)
    end

    context "when the shared examples are defined in the same file as the spec" do

      it 'prints the line number where the assertion failed in the local file' do
        run_command("#{Dir.pwd}/tmp/aruba/local_shared_examples_spec.rb")

        expect(last_cmd_stdout).to include(<<-MSG
Failed examples:

rspec ./local_shared_examples_spec.rb:4 #  the first context behaves like a failing spec fails
rspec ./local_shared_examples_spec.rb:4 #  the second context behaves like a failing spec fails
        MSG
        )
      end
    end
    context "and the shared examples are defined in a separate file" do
      it 'prints the line number where the `it_behaves_like` was called in the local file' do

        run_command("#{Dir.pwd}/tmp/aruba/non_local_shared_examples_spec.rb")
        expect(last_cmd_stdout).to include(<<-MSG
Failed examples:

rspec ./non_local_shared_examples_spec.rb:4 #  the first context behaves like a failing spec fails
rspec ./non_local_shared_examples_spec.rb:8 #  the second context behaves like a failing spec fails
        MSG
        )
      end
    end
  end
end
