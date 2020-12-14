require 'test/unit/assertions'

module RSpec
  module Core
    # @private
    module TestUnitAssertionsAdapter
      include ::Test::Unit::Assertions

      # Only if Minitest 5.x is included / loaded do we need to worry about
      # adding a shim, older versions automatically included their assertion module.
      if defined?(::Minitest::Assertions) && ancestors.include?(::Minitest::Assertions)
        require 'rspec/core/minitest_assertions_adapter'
        include ::RSpec::Core::MinitestAssertionsAdapter
      end
    end
  end
end
