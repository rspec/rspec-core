module RSpec
  module Core
    module DidYouMean
      # Service object to provide did_you_mean suggestions
      # based on https://github.com/yuki24/did_you_mean
      class Suggestions
        CUT_OFF = 0.834 # Lowest acceptable proximity to be considered probable
        MAX_SUGGESTIONS = 3 # Maximum number of suggestions that can be provided.
        attr_reader :relative_file_name, :exception

        def initialize(relative_file_name, exception)
          @relative_file_name = relative_file_name
          @exception = exception
        end

        # provide probable suggestions if a LoadError
        def call
          return unless exception.class == LoadError

          probables = find_probables
          return unless probables.any?

          short_list = probables.sort_by { |_, proximity| proximity }.reverse[0...MAX_SUGGESTIONS]
          formats short_list
        end

        private

        def formats(short_list)
          rspec_format = short_list.map { |s, _| "rspec ./#{s}" }
          red_font(top_and_tail rspec_format)
        end

        def top_and_tail(rspec_format)
          spaces = ' ' * 20
          rspec_format.insert(0, ' - Did you mean?').join("\n#{spaces}") + "\n"
        end

        def find_probables
          possibilities = Dir["spec/**/*.rb"]
          name = relative_file_name.sub('./', '')
          possibilities.map do |p|
            proximity = DidYouMean::Proximity.new(p, name).call
            [p,  DidYouMean::Proximity.new(p, name).call] if proximity >= CUT_OFF
          end.compact
        end

        def red_font(mytext)
          "\e[31m#{mytext}\e[0m"
        end
      end
    end
  end
end
