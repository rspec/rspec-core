require 'rspec/mocks/framework'
require 'rspec/mocks/extensions'

$rspec_mocks ||= RSpec::Mocks::Space.new

RSpec.subscribe(:before_befores) do |example|
  example.extend RSpec::Mocks::ExampleMethods
end

RSpec.subscribe(:before_afters) do |example|
  begin
    $rspec_mocks.verify_all
  ensure
    $rspec_mocks.reset_all
  end
end
