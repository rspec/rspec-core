RSpec::Support.require_rspec_core "formatters/base_formatter"

module RSpec
  module Core
    module Formatters
      # @private
      class FailureListFormatter < BaseFormatter
        Formatters.register self, :example_failed, :dump_profile, :message

        def example_failed(failure)
          exceptions(failure).each do |ex|
            locations = find_locations ex

            if locations
              locations.each do |location|
                output.puts location
              end
            else
              output.puts "#{failure.example.location}:E:#{one_line ex}"
            end
          end
        end

        # Discard profile and messages
        #
        # These outputs are not really relevant in the context of this failure
        # list formatter.
        def dump_profile(_profile); end
        def message(_message); end

        private

        # @return [Array<Exception>]
        def exceptions(failure)
          if failure.exception.respond_to?(:all_exceptions)
            failure.exception.all_exceptions
          else
            [failure.exception]
          end
        end

        # @return [String]
        def one_line(exception)
          exception.message.lines.map(&:strip).reject(&:empty?).join ' '
        end

        # @return [Array<String>, nil] relevant location with relative path, if any
        def find_locations(exception)
          require 'pathname'

          bt        = exception.backtrace or return
          exclude   = backtrace_exclusion_patterns
          bt_lines  = bt.reject { |l| exclude =~ l } or return
          locations = nil

          bt_lines.each do |bt_line|
            md            = bt_line.match(/^(.+?):(\d+):(.*)/) or next
            path, nr, loc = Pathname.new(md[1]), md[2], md[3]

            if path.absolute? && path.to_s.start_with?(Dir.pwd)
              path = path.relative_path_from(Pathname.pwd).to_s
              path = './' + path unless path =~ %r{^\.\.?/}
            end

            locations ||= ["#{path}:#{nr}:E:#{one_line exception}"]
            locations <<   "#{path}:#{nr}:I:#{loc}"
          end

          locations
        end

        # @return [Regexp]
        def backtrace_exclusion_patterns
          Regexp.union(
            *RSpec.configuration.backtrace_exclusion_patterns,
            /^\(\w+\):/ # also exclude ERB/eval lines
          )
        end
      end
    end
  end
end
