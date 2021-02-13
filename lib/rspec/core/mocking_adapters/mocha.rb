require 'mocha/api'

module RSpec
  module Core
    module MockingAdapters
      # @private
      module Mocha
        def self.framework_name
          :mocha
        end

        include ::Mocha::API

        def setup_mocks_for_rspec
          mocha_setup
        end

        def verify_mocks_for_rspec
          mocha_verify
        end

        def teardown_mocks_for_rspec
          mocha_teardown
        end
      end
    end
  end
end
