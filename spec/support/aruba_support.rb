module ArubaLoader
  extend RSpec::Support::WithIsolatedStdErr
  with_isolated_stderr do
    require 'aruba/api'
  end
end

RSpec.shared_context "aruba support" do
  include Aruba::Api
  let(:stderr) { StringIO.new }
  let(:stdout) { StringIO.new }

  attr_reader :last_cmd_stdout, :last_cmd_stderr, :last_cmd_exit_status

  def run_command(cmd)
    RSpec.configuration.color = true

    temp_stdout = StringIO.new
    temp_stderr = StringIO.new

    # So that `RSpec.warning` will go to temp_stderr.
    allow(::Kernel).to receive(:warn) { |msg| temp_stderr.puts(msg) }
    cmd_parts = Shellwords.split(cmd)

    handle_current_dir_change do
      cd '.' do
        @last_cmd_exit_status = RSpec::Core::Runner.run(cmd_parts, temp_stderr, temp_stdout)
      end
    end
  ensure
    RSpec.reset
    RSpec.configuration.color = true

    # Ensure it gets cached with a proper value -- if we leave it set to nil,
    # and the next spec operates in a different dir, it could get set to an
    # invalid value.
    RSpec::Core::Metadata.relative_path_regex

    @last_cmd_stdout = temp_stdout.string
    @last_cmd_stderr = temp_stderr.string
    stdout.write(@last_cmd_stdout)
    stderr.write(@last_cmd_stderr)
  end

  def write_file_formatted(file_name, contents)
    # remove blank line at the start of the string and
    # strip extra indentation.
    formatted_contents = unindent(contents.sub(/\A\n/, ""))
    write_file file_name, formatted_contents
  end

  # Intended for use with indented heredocs.
  # taken from Ruby Tapas:
  # https://rubytapas.dpdcart.com/subscriber/post?id=616#files
  def unindent(s)
    s.gsub(/^#{s.scan(/^[ \t]+(?=\S)/).min}/, "")
  end
end

RSpec.configure do |c|
  c.define_derived_metadata(:file_path => %r{spec/integration}) do |meta|
    meta[:slow] = true
  end
end
