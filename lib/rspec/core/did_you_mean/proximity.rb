module RSpec
  module Core
    module DidYouMean
      # class to calculate jaro_winkler distance based on
      # https://github.com/yuki24/did_you_mean/blob/master/lib/did_you_mean/jaro_winkler.rb
      class Proximity
        WEIGHT    = 0.1 # weight to be given to earlier parts of string
        THRESHOLD = 0.7 # Threshold for giving priority to earlier part of string
        attr_reader :str1, :str2
        attr_reader :length1, :length2, :m, :t, :range, :flags1, :flags2
        def initialize(str1, str2)
          @str1 = str1
          @str2 = str2
        end

        # compare distance between two strings
        def call
          jaro_distance = distance str1, str2

          if jaro_distance > THRESHOLD
            codepoints2  = codepoints str2
            prefix_bonus = 0

            i = 0
            str1.each_codepoint do |char1|
              char1 == codepoints2[i] && i < 4 ? prefix_bonus += 1 : break
              i += 1
            end

            jaro_distance + (prefix_bonus * WEIGHT * (1 - jaro_distance))
          else
            jaro_distance
          end
        end

        private

        def distance(str1, str2)
          str1, str2 = str2, str1 if str1.length > str2.length
          initialise_flags_counters str1, str2
          str1_codepoints = codepoints str1
          str2_codepoints = codepoints str2
          first_pass(str1_codepoints, str2_codepoints)
          second_pass(str1_codepoints, str2_codepoints)
        end

        def first_pass(str1_codepoints, str2_codepoints)
          i = 0
          while i < length1
            last = i + range
            j    = (i >= range) ? i - range : 0

            while j <= last
              if flags2[j] == 0 && str1_codepoints[i] == str2_codepoints[j]
                @flags2 |= (1 << j)
                @flags1 |= (1 << i)
                @m += 1
                break
              end

              j += 1
            end

            i += 1
          end
        end

        def second_pass(str1_codepoints, str2_codepoints)
          k = i = 0
          while i < length1
            break if flags1[i] == 0
            j = index = k

            k = while j < length2
                  index = j
                  break(j + 1) if flags2[j] != 0

                  j += 1
                end

            @t += 1 if str1_codepoints[i] != str2_codepoints[index]

            i += 1
          end
          @t = (t / 2).floor

          @m == 0 ? 0 : (m / length1 + m / length2 + (m - t) / m) / 3
        end

        def initialise_flags_counters(str1, str2)
          @length1, @length2 = str1.length, str2.length
          @m          = 0.0
          @t          = 0.0
          @range      = (length2 / 2).floor - 1
          @range      = 0 if range < 0
          @flags1     = 0
          @flags2     = 0
        end

        def codepoints(str)
          # implementation of string.codepoints for pre 1.9.1 rubies
          # Note the pre 1.9.1 version only works on ASCII strings not on UTF8.
          # It appears to me that prior to 1.9.1 UTF8 was not fully supported.
          # Need to disable some cops because the character literal had
          # a different meaning in pre 1.9.1 rubies so some cops do not make sense.
          # rubocop:disable Style/CharacterLiteral
          # rubocop:disable Lint/UnusedBlockArgument
          ruby_version_high_enough? ? str.codepoints : str.bytes.map { |b| ?b }
          # rubocop:enable Style/CharacterLiteral
          # rubocop:enable Lint/UnusedBlockArgument
        end

        # checks ruby version high enough to support string.codepoints
        def ruby_version_high_enough?
          return Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('1.9.1') if defined? RUBY_VERSION
          return false unless defined? JRUBY_VERSION
          Gem::Version.new(JRUBY_VERSION) >= Gem::Version.new('1.9.1')
        end
      end
    end
  end
end
