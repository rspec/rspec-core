shared_context :example_group => {:file_path => /spec\/integration/} do
  include Aruba::Api

  before(:all) { FileUtils.rm_rf(current_dir) }
  let(:stderr) { StringIO.new }
  let(:stdout) { StringIO.new }

  def run_command(cmd)
    RSpec::Core::Runner.run(cmd.split, stderr, stdout)
  end
end