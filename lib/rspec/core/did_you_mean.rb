module RSpec
  module Core
    # Service object to provide did_you_mean suggestions
    # based on https://github.com/yuki24/did_you_mean
    class DidYouMean
      CUT_OFF = 0.15 # Lowest acceptable nearness to be considered probable
      MAX_SUGGESTIONS = 3 # Maximum number of suggestions that can be provided.
      attr_reader :relative_file_name, :exception

      def initialize(relative_file_name, exception=nil)
        @relative_file_name = relative_file_name
        @exception = exception
      end

      if RUBY_VERSION.to_f >= 2.0
        # provide probable suggestions if a LoadError
        def call
          return unless exception.class == LoadError

          probables = find_probables
          return unless probables.any?

          short_list = probables.sort_by { |_, proximity| proximity }[0...MAX_SUGGESTIONS]
          formats short_list
        end
      else
        # return nil
        def call
        end
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
        possibilities.map do |possible|
          [possible,  proximity(possible, name)] if proximity(possible, name) <= CUT_OFF
        end.compact
      end

      def red_font(mytext)
        "\e[31m#{mytext}\e[0m"
      end

      # based on
      # https://github.com/ioquatix/build-text/blob/master/lib/build/text/merge.rb
      def levenshtein_distance(str1, str2)
        n = str1.length
        m = str2.length
        return m if n == 0
        return n if m == 0
        d = (0..m).to_a
        x = nil
        n.times do |i|
          e = i + 1
          m.times do |j|
            cost = (str1[i] == str2[j]) ? 0 : 1
            x = [
              d[j + 1] + 1, # insertion
              e + 1,      # deletion
              d[j] + cost # substitution
            ].min
            d[j] = e
            e = x
          end
          d[m] = x
        end
        return x
      end

      def proximity(str1, str2)
        distance = levenshtein_distance(str1, str2)
        average_length = (str1.length + str2.length) / 2.0
        distance.to_f / average_length
      end
    end
  end
end
