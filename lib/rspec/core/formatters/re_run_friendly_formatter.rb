RSpec::Support.require_rspec_core "formatters/immediate_feedback_formatter"

# This formatter extends the ImmediateFeedbackFormatter so that you get a nice set of commands to
# either re-run:
# 1. Individual failing tests, one per line.
# 2. All individual failing tests, in one rspec command.
# 3. All failing test files
class ReRunFriendlyFormatter < ImmediateFeedbackFormatter
  RSpec::Core::Formatters.register self, :dump_summary

  def dump_summary(summary)
    failed_files = failed_files(summary)

    unless summary.failed_examples.empty?
      output.puts summary.colorized_rerun_commands

      output.puts
      output.puts "Rerun all failed examples:"
      output.puts

      output.puts failure_colored("rspec #{failed_examples_line(summary)}")

      output.puts
      output.puts "Rerun all files containing failures:"
      output.puts

      output.puts failure_colored("rspec #{failed_files.join(" ")}")

      output.puts
    end

    output.puts "\nFinished in #{summary.formatted_duration} " \
                    "(files took #{summary.formatted_load_time} to load)\n" \
                    "#{summary.colorized_totals_line}\n"
  end

  private

  include RSpec::Core::ShellEscape

  def failed_files(summary)
    summary.failed_examples.map do |example|
      location_with_line_etc = example.location_rerun_argument
      location_with_line_etc.match(/(.*\.rb).*$/)[1]
    end.uniq
  end

  def failed_examples_line(summary)
    summary.failed_examples.map do |example|
      rerun_argument_for(example)
    end.join(" ")
  end

  def rerun_argument_for(example)
    location = example.location_rerun_argument
    return location unless duplicate_rerun_locations.include?(location)
    conditionally_quote(example.id)
  end

  def duplicate_rerun_locations
    @duplicate_rerun_locations ||= begin
      locations = RSpec.world.all_examples.map(&:location_rerun_argument)

      result = Set.new.tap do |s|
        locations.group_by { |l| l }.each do |l, ls|
          s << l if ls.count > 1
        end
      end
      result
    end
  end

  def failure_colored(str)
    RSpec::Core::Formatters::ConsoleCodes.wrap(str, :failure)
  end
end
