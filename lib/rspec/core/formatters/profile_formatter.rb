RSpec::Support.require_rspec_core "formatters/console_codes"

module RSpec
  module Core
    module Formatters
      # @api private
      # Formatter for providing profile output.
      class ProfileFormatter
        Formatters.register self, :dump_profile, :example_group_started, :example_group_finished, :example_started

        def initialize(output)
          @example_groups = {} #todo rename
          @output = output
        end

        def example_group_started(notification)
          group_id = notification.group.id
          @example_groups[group_id] = Hash.new(0)
          @example_groups[group_id][:start] = Time.now
          @example_groups[group_id][:description] = notification.group.top_level_description
        end

        def example_group_finished(notification)
          group_id = notification.group.id
          @example_groups[group_id][:total_time] =  Time.now - @example_groups[group_id][:start]
        end

        def example_started(notification)
          group_id = notification.example.example_group.parent_groups.last.id
          @example_groups[group_id][:count] += 1
        end

        # @private
        attr_reader :output

        # @api public
        #
        # This method is invoked after the dumping the summary if profiling is
        # enabled.
        #
        # @param profile [ProfileNotification] containing duration,
        #   slowest_examples and slowest_example_groups
        def dump_profile(profile)
          dump_profile_slowest_examples(profile)
          dump_profile_slowest_example_groups(profile)
        end

      private

        def dump_profile_slowest_examples(profile)
          @output.puts "\nTop #{profile.slowest_examples.size} slowest " \
            "examples (#{Helpers.format_seconds(profile.slow_duration)} " \
            "seconds, #{profile.percentage}% of total time):\n"

          profile.slowest_examples.each do |example|
            @output.puts "  #{example.full_description}"
            @output.puts "    #{bold(Helpers.format_seconds(example.execution_result.run_time))} " \
                         "#{bold("seconds")} #{format_caller(example.location)}"
          end
        end

        def dump_profile_slowest_example_groups(profile)
          slowest_groups = profile.calculate_slowest_groups(@example_groups)
          return if slowest_groups.empty?

          @output.puts "\nTop #{slowest_groups.size} slowest example groups:"
          slowest_groups.each do |loc, hash|
            average = "#{bold(Helpers.format_seconds(hash[:average]))} #{bold("seconds")} average"
            total   = "#{Helpers.format_seconds(hash[:total_time])} seconds"
            count   = Helpers.pluralize(hash[:count], "example")
            @output.puts "  #{hash[:description]}"
            @output.puts "    #{average} (#{total} / #{count}) #{loc}"
          end
        end

        def format_caller(caller_info)
          RSpec.configuration.backtrace_formatter.backtrace_line(
            caller_info.to_s.split(':in `block').first)
        end

        def bold(text)
          ConsoleCodes.wrap(text, :bold)
        end
      end
    end
  end
end
