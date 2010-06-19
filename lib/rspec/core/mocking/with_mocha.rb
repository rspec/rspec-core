require 'mocha/standalone'
require 'mocha/object'

RSpec.subscribe(:example_started) do |example|
  # Mocha::Standalone was deprecated as of Mocha 0.9.7.  
  begin
    example.extend Mocha::API
  rescue NameError
    example.extend Mocha::Standalone
  end
  example.mocha_setup
end

RSpec.subscribe(:example_finished) do |example|
  begin
    example.mocha_verify
  ensure
    example.mocha_teardown
  end
end
