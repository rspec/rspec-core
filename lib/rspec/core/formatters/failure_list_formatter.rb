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
            location = find_location(exception) || failure.example.location

            output.puts "#{location}:E:#{reason}"
          end
        end

        # Discard profile and messages
        #
        # These outputs are not really relevant in the context of this failure
        # list formatter.
        def dump_profile(_profile); end
        def message(_message); end

        private

        # @return [String] relevant location with relative path, if possible
        # @return [nil] if no location could be found
        def find_location(exception)
          require 'pathname'

          bt       = exception.backtrace or return
          exclude  = backtrace_exclusion_patterns
          bt_line  = bt.find { |l| exclude !~ l } or return
          md       = bt_line.match(/^(.+?):(\d+):/) or return
          path, nr = Pathname.new(md[1]), md[2]

          if path.absolute? && path.to_s.start_with?(Dir.pwd)
            rel_path = path.relative_path_from(Pathname.pwd).to_s
            rel_path = './' + rel_path unless rel_path =~ %r{^\.\.?/}
            "#{rel_path}:#{nr}"
          else
            "#{path}:#{nr}"
          end
        end

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
