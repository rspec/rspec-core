require 'rspec/mocks/framework'
require 'rspec/mocks/extensions'

$rspec_mocks ||= RSpec::Mocks::Space.new

RSpec.subscribe(:example_started) do |example|
  example.extend RSpec::Mocks::ExampleMethods
end

RSpec.subscribe(:example_finished) do |example|
  begin
    $rspec_mocks.verify_all
  ensure
    $rspec_mocks.reset_all
  end
end
