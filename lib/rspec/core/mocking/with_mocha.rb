require 'mocha/standalone'
require 'mocha/object'

RSpec.subscribe(:before_befores) do |example|
  # Mocha::Standalone was deprecated as of Mocha 0.9.7.  
  begin
    example.extend Mocha::API
  rescue NameError
    example.extend Mocha::Standalone
  end
  example.mocha_setup
end

RSpec.subscribe(:before_afters) do |example|
  begin
    example.mocha_verify
  ensure
    example.mocha_teardown
  end
end
