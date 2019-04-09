RSpec::Support.require_rspec_core "formatters/base_formatter"

module RSpec
  module Core
    module Formatters
      # @private
      class MinimalFormatter < BaseFormatter
        Formatters.register self, :example_failed, :dump_profile

        def example_failed(failure)
          output.puts "#{failure.example.location}:#{failure.example.description}"
        end

        def dump_profile(_profile); end
      end
    end
  end
end
