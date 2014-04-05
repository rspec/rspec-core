require 'spec_helper'

describe "filtering by location", :type => :aruba do
  let(:stderr) { StringIO.new }
  let(:stdout) { StringIO.new }

  context "with a shared example containing a context in a separate file" do
    before(:all) do
      write_file 'spec/simple_spec.rb', """
        require File.join(File.dirname(__FILE__), 'shared_example.rb')

        RSpec.describe 'top level' do
          it_behaves_like 'a shared example'
        end
      """

      write_file 'spec/shared_example.rb', """
        RSpec.shared_examples_for 'a shared example' do
          it 'succeeds' do
          end

          context 'with a nested context' do
            it 'succeeds' do
            end
          end
        end
      """
    end

    it "runs the example nested inside the shared" do
      run_command 'tmp/aruba/spec/simple_spec.rb:3'
      expect(stdout.string).to match(/2 examples, 0 failures/)
    end
  end

  def run_command(cmd)
    RSpec::Core::Runner.run(cmd.split, stderr, stdout)
  end
end
