require 'rspec/core/formatters/failure_list_formatter'

module RSpec::Core::Formatters
  RSpec.describe FailureListFormatter do
    include FormatterSupport

    it 'produces the expected full output' do
      output = run_example_specs_with_formatter('failures')
      expect(output).to eq(<<-EOS.gsub(/^\s+\|/, ''))
        |./spec/rspec/core/resources/formatter_specs.rb:4:E:Expected example to fail since it is pending, but it passed.
        |./spec/rspec/core/resources/formatter_specs.rb:37:E:expected: 2 got: 1 (compared using ==)
        |./spec/rspec/core/resources/formatter_specs.rb:41:E:expected: 2 got: 1 (compared using ==)
        |./spec/rspec/core/resources/formatter_specs.rb:42:E:expected: 4 got: 3 (compared using ==)
        |./spec/rspec/core/resources/formatter_specs.rb:50:E:foo
        |/foo.html.erb:1:E:Exception
        |./spec/rspec/core/resources/formatter_specs.rb:71:E:boom
      EOS
    end
  end
end
