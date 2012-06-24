require 'spec_helper'

describe 'command line' do
  before :all do
    write_file 'spec/addition_spec.rb', """
      describe 'addition' do
        it 'adds things' do
          (1 + 2).should eq(3)
        end
      end
    """
    write_file 'spec/example/multiplication_spec.rb', """
      describe 'multiplication' do
        it 'multiplies things' do
          (3 * 2).should eq(6)
        end
      end
    """
    write_file 'spec/subtraction.rb', """
      describe 'subtraction' do
        it 'subtracts things' do
          (2 - 1).should eq(1)
        end
      end
    """
    write_file 'spec/division.spec', """
      describe 'division' do
        it 'divides things' do
          (4 / 2).should eq(2)
        end
      end
    """
  end

  describe 'default pattern' do
    it 'runs the examples matching "spec/**/*_spec.rb"' do
      run_command 'tmp/aruba/spec'
      stdout.string.should include('2 examples, 0 failures')
    end
  end

  describe '--pattern' do
    it 'runs the examples matching the specified pattern' do
      run_command 'tmp/aruba/spec --pattern *.spec'
      stdout.string.should include('1 example, 0 failures')
    end
  end
end
