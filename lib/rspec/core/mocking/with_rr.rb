require 'rr'

RSpec.configuration.backtrace_clean_patterns.push(RR::Errors::BACKTRACE_IDENTIFIER)

RSpec.subscribe(:example_started) do |example|
  example.extend RR::Extensions::InstanceMethods
  RR::Space.instance.reset
end

RSpec.subscribe(:example_executed) do |example|
  begin
    RR::Space.instance.verify_doubles
  ensure
    RR::Space.instance.reset
  end
end
