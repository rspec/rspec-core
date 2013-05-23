module RSpec
  module Core
    module Deprecation
      # @private
      #
      # Used internally to print deprecation warnings
      def deprecate(deprecated, replacement_or_hash={}, ignore_version=nil)
        # Temporarily support old and new APIs while we transition the other
        # rspec libs to use a hash for the 2nd arg and no version arg
        data = Hash === replacement_or_hash ? replacement_or_hash : { :replacement => replacement_or_hash }
        RSpec.configuration.reporter.deprecation data.merge(:deprecated => deprecated, :call_site => caller(0)[2])
      end

      # @private
      #
      # Used internally to print deprecation warnings
      def warn_deprecation(message)
        RSpec.configuration.reporter.deprecation :message => message
      end
    end
  end

  extend(Core::Deprecation)
end
