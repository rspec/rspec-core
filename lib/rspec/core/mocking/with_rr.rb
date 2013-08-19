require 'rr'

if RSpec.configuration.respond_to?(:backtrace_exclusion_patterns)
  RSpec.configuration.backtrace_exclusion_patterns.push(RR::Errors::BACKTRACE_IDENTIFIER)
else
  RSpec.configuration.backtrace_clean_patterns.push(RR::Errors::BACKTRACE_IDENTIFIER)
end

module RSpec
  module Core
    module MockFrameworkAdapter

      def self.framework_name; :rr end

      include RR::Extensions::InstanceMethods

      def setup_mocks_for_rspec
        RR::Space.instance.reset
      end

      def verify_mocks_for_rspec
        RR::Space.instance.verify_doubles
      end

      def teardown_mocks_for_rspec
        RR::Space.instance.reset
      end

    end
  end
end
