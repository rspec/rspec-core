module RSpec
  module Core
    # @private
    class BacktraceFormatter
      # @private
      attr_accessor :exclusion_patterns, :inclusion_patterns

      def initialize
        @full_backtrace = false

        patterns = [
          "/lib\d*/ruby/",
          "org/jruby/",
          "bin/",
          "/gems/",
        ].map { |s| Regexp.new(s.gsub("/", File::SEPARATOR)) }

        @system_exclusion_patterns = [Regexp.union(RSpec::CallerFilter::IGNORE_REGEX, *patterns)]
        @exclusion_patterns = [] + @system_exclusion_patterns
        @inclusion_patterns = [Regexp.new(Dir.getwd)]
      end

      def full_backtrace=(full_backtrace)
        @full_backtrace = full_backtrace
      end

      def full_backtrace?
        @full_backtrace || @exclusion_patterns.empty?
      end

      def format_backtrace(backtrace, options = {})
        return backtrace if options[:full_backtrace]

        backtrace.map { |l| backtrace_line(l) }.compact.
          tap do |filtered|
            if filtered.empty?
              filtered.concat backtrace
              filtered << ""
              filtered << "  Showing full backtrace because every line was filtered out."
              filtered << "  See docs for RSpec::Configuration#backtrace_exclusion_patterns and"
              filtered << "  RSpec::Configuration#backtrace_inclusion_patterns for more information."
            end
          end
      end

      def backtrace_line(line)
        RSpec::Core::Metadata::relative_path(line) unless exclude?(line)
      rescue SecurityError
        nil
      end

      def exclude?(line)
        return false if @full_backtrace
        matches_an_exclusion_pattern?(line) &&
          doesnt_match_inclusion_pattern_unless_system_exclusion?(line)
      end

    private

      def matches_an_exclusion_pattern?(line)
        matches_unless_working_directory? @exclusion_patterns, line
      end

      def doesnt_match_inclusion_pattern_unless_system_exclusion?(line)
        matches_unless_working_directory?(@system_exclusion_patterns, line) ||
          @inclusion_patterns.none? { |p| p =~ line }
      end

      def matches_unless_working_directory?(patterns, line)
        patterns.any? { |p| line.gsub(Dir.getwd,'') =~ p }
      end

    end
  end
end
