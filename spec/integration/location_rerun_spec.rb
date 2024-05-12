require 'support/aruba_support'

RSpec.describe 'Failed spec rerun location' do
  subject(:run_spec) do
    file = cd('.') { "#{Dir.pwd}/failing_spec.rb" }
    load file
    run_command 'failing_spec.rb'
  end

  include_context "aruba support"

  before do
    setup_aruba
    write_file "failing_spec.rb", "
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
  end

  it 'prints the example ids' do
    run_spec

    expect(last_cmd_stdout).to include("/failing_spec.rb[1:1:1:1]")
    expect(last_cmd_stdout).to include("/failing_spec.rb[1:2:1:1]")
  end

  context "when config.location_rerun_uses_line_number is set to true" do
    before do
      RSpec.configuration.location_rerun_uses_line_number = true
    end

    it 'prints the line numbers' do
      run_spec

      expect(last_cmd_stdout).to include("/failing_spec.rb:10")
      expect(last_cmd_stdout).to include("/failing_spec.rb:14")
    end
  end
end
