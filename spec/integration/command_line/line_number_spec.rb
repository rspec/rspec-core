require 'spec_helper'

describe 'command line' do
  describe '--line_number' do
    before :all do
      write_file 'spec/example_spec.rb', """
        describe 9 do
          it 'should be > 8' do
            9.should be > 8
          end

          it 'should be < 10' do
            9.should be < 10
          end

          it 'should be 3 squared' do
            9.should be 3*3
          end

          it { should be > 7 }
          it { should be < 11 }
        end
      """
    end

    it 'works when specified multiple times' do
      run_command 'tmp/aruba/spec/example_spec.rb --line_number 2 --line_number 6 --format doc'
      stdout.string.should include('should be > 8')
      stdout.string.should include('should be < 10')
      stdout.string.should_not include('should be 3*3')
    end

    it 'works for one-liners' do
      run_command 'tmp/aruba/spec/example_spec.rb --line_number 15 --format doc'
      stdout.string.should include('example at ./tmp/aruba/spec/example_spec.rb:15')
      stdout.string.should_not include('example at ./tmp/aruba/spec/example_spec.rb:16')
    end
  end
end
