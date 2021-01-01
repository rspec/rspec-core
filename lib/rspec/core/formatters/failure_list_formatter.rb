RSpec::Support.require_rspec_core "formatters/base_formatter"

module RSpec
  module Core
    module Formatters
      # @private
      class FailureListFormatter < BaseFormatter
        Formatters.register self, :example_failed, :dump_profile, :message

        def example_failed(failure)
          if failure.exception.respond_to?(:all_exceptions)
            exceptions = failure.exception.all_exceptions
          else
            exceptions = [failure.exception]
          end

          exceptions.each do |exception|
            reason   = exception.message.lines.map(&:strip).reject(&:empty?).join ' '
            location = find_relevant_location failure, exception

            output.puts "#{location}:#{reason}"
          end
        end

        # Discard profile and messages
        #
        # These outputs are not really relevant in the context of this failure
        # list formatter.
        def dump_profile(_profile); end
        def message(_message); end

        private

        # @return [String] relevant locaton
        def find_relevant_location(failure, exception)
          bt = exception.backtrace

          if bt && (line = bt.find { |l| backtrace_exclusion_patterns !~ l })
            line[/[^:]+:\d+/]
          else
            failure.example.location
          end
        end

        def backtrace_exclusion_patterns
          @backtrace_exclusion_patterns ||=
            begin
              # ERB/eval lines
              non_file = /^\(\w+\):/
              Regexp.union(*RSpec.configuration.backtrace_exclusion_patterns, non_file)
            end
        end
      end
    end
  end
end
