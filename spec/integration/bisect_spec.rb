RSpec::Support.require_rspec_core "formatters/bisect_progress_formatter"

module RSpec::Core
  RSpec.describe "Bisect", :slow, :simulate_shell_allowing_unquoted_ids do
    include FormatterSupport

    def bisect(cli_args, expected_status=nil)
      options = ConfigurationOptions.new(cli_args)

      expect {
        status = Invocations::Bisect.new.call(options, formatter_output, formatter_output)
        expect(status).to eq(expected_status) if expected_status
      }.to avoid_outputting.to_stdout_from_any_process.and avoid_outputting.to_stderr_from_any_process

      normalize_durations(formatter_output.string)
    end

    before do
      if RSpec::Support::Ruby.jruby? && RSpec::Support::Ruby.jruby_version == '9.1.17.0'
        skip "These specs are currently broken on JRuby 9.1.17.0"
      end
    end

    context "when a load-time problem occurs while running the suite" do
      it 'surfaces the stdout and stderr output to the user' do
        output = bisect(%w[spec/rspec/core/resources/fail_on_load_spec.rb_], 1)
        expect(output).to include("Bisect failed!", "undefined method #{quoted('contex')}", "About to call misspelled method")
      end
    end

    context "when the spec ordering is inconsistent" do
      it 'stops bisecting and surfaces the problem to the user' do
        output = bisect(%W[spec/rspec/core/resources/inconsistently_ordered_specs.rb], 1)
        expect(output).to include("Bisect failed!", "The example ordering is inconsistent")
      end
    end

    context "when the spec ordering is consistent" do
      it 'returns the minimal reproduction command' do
        output = bisect(%w[
          --order defined
          spec/rspec/core/resources/bisect/consistently_ordered_1_specs.rb
          spec/rspec/core/resources/bisect/consistently_ordered_2_specs.rb
          spec/rspec/core/resources/bisect/consistently_ordered_3_specs.rb
          spec/rspec/core/resources/bisect/consistently_ordered_4_specs.rb
        ])
        expect(output).to include("Bisect complete!", "rspec ./spec/rspec/core/resources/bisect/consistently_ordered_2_specs.rb[1:1] ./spec/rspec/core/resources/bisect/consistently_ordered_3_specs.rb[1:1]")
      end
    end

    context "when the bisect command saturates the pipe" do
      # On OSX and Linux a file descriptor limit meant that the bisect process got stuck at a certain limit.
      # This test demonstrates that we can run large bisects above this limit (found to be at time of commit).
      # See: https://github.com/rspec/rspec-core/pull/2669
      it 'does not hit pipe size limit and does not get stuck' do
        output = bisect(%W[spec/rspec/core/resources/blocking_pipe_bisect_spec.rb_], 1)
        expect(output).to include("No failures found.")
      end

      it 'does not leave zombie processes', :unless => RSpec::Support::OS.windows? do
        bisect(['--format', 'json', 'spec/rspec/core/resources/blocking_pipe_bisect_spec.rb_'], 1)

        zombie_process = RSpecChildProcess.new(Process.pid).zombie_process
        expect(zombie_process).to eq([]), <<-MSG
          Expected no zombie processes got #{zombie_process.count}:
            #{zombie_process}
        MSG
      end
    end

    context "when specs use the `output` expectation" do
      it 'does not break the capture helper' do
        output = bisect(%w[spec/rspec/core/resources/bisect/output_capture_specs.rb])
        expect(output).to include("No failures found")
      end
    end

    class RSpecChildProcess
      Ps = Struct.new(:pid, :ppid, :state, :command)

      def initialize(pid)
        @list = child_process_list(pid)
      end

      def zombie_process
        @list.select { |child_process| child_process.state =~ /Z/ }
      end

      private

      def child_process_list(pid)
        childs_process_list = []
        ps_pipe = `ps -o pid=,ppid=,state=,args= | grep #{pid}`

        ps_pipe.split(/\n/).map do |line|
          ps_part = line.lstrip.split(/\s+/)

          next unless ps_part[1].to_i == pid

          child_process = Ps.new
          child_process.pid = ps_part[0]
          child_process.ppid = ps_part[1]
          child_process.state = ps_part[2]
          child_process.command = ps_part[3..-1].join(' ')

          childs_process_list << child_process
        end
        childs_process_list
      end
    end
  end
end
