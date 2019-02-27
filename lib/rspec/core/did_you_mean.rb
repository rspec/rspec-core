module RSpec
  module Core
    # Service object to provide did_you_mean suggestions
    class DidYouMean
      attr_reader :relative_file_name

      def initialize(relative_file_name)
        @relative_file_name = relative_file_name
      end

      if defined?(::DidYouMean::SpellChecker)
        # provide probable suggestions if a LoadError
        def call
          checker = ::DidYouMean::SpellChecker.new(:dictionary => Dir["spec/**/*.rb"])
          probables = checker.correct(relative_file_name)
          return unless probables.any?

          formats probables
        end
      else # ruby 2.3.2 or less
        # return nil if API for ::DidYouMean::SpellChecker not supported
        def call
        end
      end

      private

      def formats(probables)
        rspec_format = probables.map { |s, _| "rspec ./#{s}" }
        red_font(top_and_tail rspec_format)
      end

      def top_and_tail(rspec_format)
        spaces = ' ' * 20
        rspec_format.insert(0, ' - Did you mean?').join("\n#{spaces}") + "\n"
      end

      def red_font(mytext)
        colorizer = ::RSpec::Core::Formatters::ConsoleCodes
        colorizer.wrap mytext, :failure
      end
    end
  end
end
