require 'support/aruba_support'
require 'support/formatter_support'

RSpec.describe 'Spec file load errors' do
  include_context "aruba support"
  include FormatterSupport

  let(:failure_exit_code) { rand(97) + 2 } # 2..99
  let(:error_exit_code) { failure_exit_code + 1 } # 3..100

  if RSpec::Support::Ruby.jruby_9000?
    let(:spec_line_suffix) { ":in `<main>'" }
  elsif RSpec::Support::Ruby.jruby?
    let(:spec_line_suffix) { ":in `(root)'" }
  elsif RUBY_VERSION == "1.8.7"
    let(:spec_line_suffix) { "" }
  else
    let(:spec_line_suffix) { ":in `<top (required)>'" }
  end

  before do
    setup_aruba

    RSpec.configure do |c|
      c.filter_gems_from_backtrace "gems/aruba"
      c.filter_gems_from_backtrace "gems/bundler"
      c.backtrace_exclusion_patterns << %r{/rspec-core/spec/} << %r{rspec_with_simplecov}
      c.failure_exit_code = failure_exit_code
      c.error_exit_code = error_exit_code
    end
  end

  it 'nicely handles load-time errors from --require files' do
    write_file_formatted "helper_with_error.rb", "raise 'boom'"

    run_command "--require ./helper_with_error"
    expect(last_cmd_exit_status).to eq(error_exit_code)
    output = normalize_durations(last_cmd_stdout)
    expect(output).to eq unindent(<<-EOS)

      An error occurred while loading ./helper_with_error.
      Failure/Error: raise 'boom'

      RuntimeError:
        boom
      # ./helper_with_error.rb:1#{spec_line_suffix}
      No examples found.


      Finished in n.nnnn seconds (files took n.nnnn seconds to load)
      0 examples, 0 failures, 1 error occurred outside of examples

    EOS
  end

  it 'prints a single error when it happens on --require files' do
    write_file_formatted "helper_with_error.rb", "raise 'boom'"

    write_file_formatted "1_spec.rb", "
      RSpec.describe 'A broken spec file that will raise when loaded' do
        raise 'kaboom'
      end
    "

    run_command "--require ./helper_with_error 1_spec.rb"
    expect(last_cmd_exit_status).to eq(error_exit_code)
    output = normalize_durations(last_cmd_stdout)
    expect(output).to eq unindent(<<-EOS)

      An error occurred while loading ./helper_with_error.
      Failure/Error: raise 'boom'

      RuntimeError:
        boom
      # ./helper_with_error.rb:1#{spec_line_suffix}
      No examples found.


      Finished in n.nnnn seconds (files took n.nnnn seconds to load)
      0 examples, 0 failures, 1 error occurred outside of examples

    EOS
  end

  it 'prints a warning when a helper file exits early' do
    write_file_formatted "helper_with_exit.rb", "exit 999"

    expect {
      run_command "--require ./helper_with_exit.rb"
    }.to raise_error(SystemExit)
    output = normalize_durations(last_cmd_stdout)
    # Remove extra line which is only shown on CRuby
    output = output.sub("# ./helper_with_exit.rb:1:in `exit'\n", "")

    if defined?(JRUBY_VERSION) && !JRUBY_VERSION.empty?
      expect(output).to eq unindent(<<-EOS)

        While loading ./helper_with_exit.rb an `exit` / `raise SystemExit` occurred, RSpec will now quit.
        Failure/Error: Unable to find org/jruby/RubyKernel.java to read failed line

        SystemExit:
          exit
        # ./helper_with_exit.rb:1#{spec_line_suffix}
      EOS
    else
      expect(output).to eq unindent(<<-EOS)

        While loading ./helper_with_exit.rb an `exit` / `raise SystemExit` occurred, RSpec will now quit.
        Failure/Error: exit 999

        SystemExit:
          exit
        # ./helper_with_exit.rb:1#{spec_line_suffix}
      EOS
    end
  end

  it 'nicely handles load-time errors in user spec files', :disable_error_highlight => true do
    write_file_formatted "1_spec.rb", "
      boom

      RSpec.describe 'Calling boom' do
        it 'will not run this example' do
          expect(1).to eq 1
        end
      end
    "

    write_file_formatted "2_spec.rb", "
      RSpec.describe 'No Error' do
        it 'will not run this example, either' do
          expect(1).to eq 1
        end
      end
    "

    write_file_formatted "3_spec.rb", "
      boom

      RSpec.describe 'Calling boom again' do
        it 'will not run this example, either' do
          expect(1).to eq 1
        end
      end
    "

    run_command "1_spec.rb 2_spec.rb 3_spec.rb"
    expect(last_cmd_exit_status).to eq(error_exit_code)
    output = normalize_durations(last_cmd_stdout)

    object_suffix =
      if RUBY_VERSION.to_f > 3.2
        ""
      else
        ":Object"
      end

    expect(output).to eq unindent(<<-EOS)

      An error occurred while loading ./1_spec.rb.
      Failure/Error: boom

      NameError:
        undefined local variable or method `boom' for main#{object_suffix}
      # ./1_spec.rb:1#{spec_line_suffix}

      An error occurred while loading ./3_spec.rb.
      Failure/Error: boom

      NameError:
        undefined local variable or method `boom' for main#{object_suffix}
      # ./3_spec.rb:1#{spec_line_suffix}


      Finished in n.nnnn seconds (files took n.nnnn seconds to load)
      0 examples, 0 failures, 2 errors occurred outside of examples

    EOS
  end

  describe 'handling syntax errors' do
    let(:formatted_output) { normalize_durations(last_cmd_stdout).gsub(Dir.pwd, '.').gsub(/\e\[[0-9;]+m/, '') }

    before(:example) do
      write_file_formatted "broken_file.rb", "
      class WorkInProgress
        def initialize(arg)
        def foo
        end
      end
      "
    end

    if RSpec::Support::RubyFeatures.supports_syntax_suggest?
      it 'uses syntax_suggest formatting when available' do
        in_sub_process do
          require "syntax_suggest"

          run_command "--require ./broken_file"
          expect(last_cmd_exit_status).to eq(error_exit_code)

          expect(formatted_output).to include unindent(<<-EOS)
            While loading ./broken_file a `raise SyntaxError` occurred, RSpec will now quit.
          EOS

          # A fix was backported to 3.2.3
          if RUBY_VERSION > '3.2.2'
            expect(formatted_output).to include unindent(<<-EOS)
            SyntaxError:
              --> ./tmp/aruba/broken_file.rb
              Unmatched keyword, missing `end' ?
                1  class WorkInProgress
              > 2    def initialize(arg)
                3    def foo
                4    end
                5  end
            EOS
          else
            expect(formatted_output).to include unindent(<<-EOS)
            SyntaxError:
              --> ./tmp/aruba/broken_file.rb
              Unmatched keyword, missing `end' ?
                1  class WorkInProgress
              > 2    def initialize(arg)
                4    end
                5  end
            EOS
          end
          expect(formatted_output).to include "./tmp/aruba/broken_file.rb:5: syntax error"

          expect(formatted_output).to include unindent(<<-EOS)
            Finished in n.nnnn seconds (files took n.nnnn seconds to load)
            0 examples, 0 failures, 1 error occurred outside of examples
          EOS
        end
      end
    else
      it 'prints a basic error when no syntax_suggest is available/loaded', :skip => RUBY_VERSION.to_f < 1.9 || RSpec::Support::Ruby.jruby? do
        run_command "--require ./broken_file"
        expect(last_cmd_exit_status).to eq(error_exit_code)

        expect(formatted_output).to include unindent(<<-EOS)
          While loading ./broken_file a `raise SyntaxError` occurred, RSpec will now quit.
          Failure/Error: __send__(method, file)
        EOS

        # This is subset of the formatted_output, it continues slightly but differs on different Rubies
        expect(formatted_output).to include "SyntaxError:\n  ./tmp/aruba/broken_file.rb:5: syntax error"

        expect(formatted_output).to include unindent(<<-EOS)
          Finished in n.nnnn seconds (files took n.nnnn seconds to load)
          0 examples, 0 failures, 1 error occurred outside of examples
        EOS
      end
    end
  end
end
