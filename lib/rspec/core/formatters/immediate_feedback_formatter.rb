RSpec::Support.require_rspec_core "formatters/base_text_formatter"

# Code is based on standard documentation formatter, but:
#
# 1. It will print full error details as soon as they are found.
# 2. It prints a full descriptive ine for each spec run, including the duration of each spec.
#
class ImmediateFeedbackFormatter < RSpec::Core::Formatters::BaseTextFormatter
  RSpec::Core::Formatters.register(self, :example_started, :example_passed, :example_pending,
                                   :example_failed )
  @@RUNNING_EXAMPLES_HASH = {}

  def dump_pending(notification)
    # Noop. Don't need to see this again.
  end

  def dump_summary(summary)
    super
    @@RUNNING_EXAMPLES_HASH.clear()
  end

  def example_started(notification)
    example_id = notification.example.id
    current_time = Time.now
    @@RUNNING_EXAMPLES_HASH[example_id] = current_time
  end

  def add_example_group(example_group)
    super
    @current_group = example_group.description
  end

  def example_failed(example_notification)
    failure_line = "#{example_description(example_notification)} "\
      "[#{RSpec::Core::Metadata::relative_path(example_notification.example.file_path)}]"
    colored_failure_line = RSpec::Core::Formatters::ConsoleCodes.wrap(failure_line, RSpec.configuration.failure_color)
    output.puts colored_failure_line
    unless ENV['TRACE'] && %w(0 no false).include?(ENV['TRACE'])
      puts example_notification.fully_formatted(next_failure_index)
    end
    output.flush
  end

  def example_passed(example_notification)
    output.puts("#{example_description(example_notification)} #{example_duration(example_notification)}")
    output.flush
  end

  def example_pending(example_notification, message = '')
    line = RSpec::Core::Formatters::ConsoleCodes.
      wrap("#{example_description(example_notification)} (Pending) #{message}",
           RSpec.configuration.pending_color)
    output.puts line
    output.flush
  end

  private

  def example_duration(example_notification)
    time_then = @@RUNNING_EXAMPLES_HASH[example_notification.example.id]
    time_then ? "(#{(Time.now - time_then).round(4)} s)" : "(duration missing)"
  end

  def example_description(example_notification)
    example_group_description(example_notification).strip + ' ' +
      example_notification.example.description.strip
  end

  def example_group_description(_example_notification)
    example_group.parent_groups.collect(&:description).reverse.join(' ')
  end

  def next_failure_index
    @next_failure_index ||= 0
    @next_failure_index += 1
  end
end
