require 'spec_helper'



RSpec.describe 'command line', :ui, :slow do
  before :each do
    @out = StringIO.new
    write_file 'spec/parallel_spec.rb', """
      RSpec.describe \"parallel run\" do
        it \"thread 0 example\" do
          sleep 1
          fail
        end

        it \"thread 1 example\" do
          sleep 1
          pass
        end

        it \"thread 2 example\" do
          sleep 1
          pass
        end

        it \"thread 3 example\" do
          sleep 1
          fail
        end

        it \"thread 4 example\" do
          sleep 1
          pass
        end

        it \"thread 5 example\" do
          sleep 1
          pass
        end
      end
    """
  end

  describe '--parallel-test' do
    it '1 thread' do
      run_command 'spec/parallel_spec.rb --parallel-test 1'
      output_str = @out.string
      validate_output(output_str)
      seconds = get_seconds(output_str).to_i
      expect(seconds).to be >= 6
    end

    it '3 threads' do
      run_command 'spec/parallel_spec.rb --parallel-test 3'
      output_str = @out.string
      validate_output(output_str)
      seconds = get_seconds(output_str).to_i
      expect(seconds).to be >= 3
      expect(seconds).to be < 6
    end

    it '6 threads' do
      run_command 'spec/parallel_spec.rb --parallel-test 6'
      output_str = @out.string
      validate_output(output_str)
      seconds = get_seconds(output_str).to_i
      expect(seconds).to be >= 1
      expect(seconds).to be < 3
    end
  end

  def run_command(cmd)
    in_current_dir do
      RSpec::Core::Runner.run(cmd.split, @out, @out)
    end
  end

  def validate_output(output_str)
    expect(output_str).to include("6 examples, 2 failures"), "output_str: #{output_str}"
    expect(output_str).to include("Finished in "), "output_str: #{output_str}"
  end

  def get_seconds(output_str)
    return output_str[/Finished in (?<match>.*) second/, "match"]
  end
end
