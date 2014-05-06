RSpec::Support.require_rspec_core "formatters/helpers"

module RSpec::Core
  # Notifications are value objects passed to formatters to provide them
  # with information about a particular event of interest.
  module Notifications

    # The `StartNotification` represents a notification sent by the reporter
    # when the suite is started. It contains the expected amount of examples
    # to be executed, and the load time of RSpec.
    #
    # @attr count [Fixnum] the number counted
    # @attr load_time [Float] the number of seconds taken to boot RSpec
    #                         and load the spec files
    StartNotification = Struct.new(:count, :load_time)

    # The `ExampleNotification` represents notifications sent by the reporter
    # which contain information about the current (or soon to be) example.
    # It is used by formatters to access information about that example.
    #
    # @example
    #   def example_started(notification)
    #     puts "Hey I started #{notification.example.description}"
    #   end
    #
    # @attr example [RSpec::Core::Example] the current example
    ExampleNotification = Struct.new(:example)

    # The `FailedExampleNotification` extends `ExampleNotification` with
    # things useful for failed specs.
    #
    # @example
    #   def example_failed(notification)
    #     puts "Hey I failed :("
    #     puts "Here's my stack trace"
    #     puts notification.exception.backtrace.join("\n")
    #   end
    #
    # @attr [RSpec::Core::Example] example the current example
    # @see ExampleNotification
    class FailedExampleNotification < ExampleNotification

      # Returns the examples failure
      #
      # @return [Exception] The example failure
      def exception
        example.execution_result.exception
      end
    end

    # The `GroupNotification` represents notifications sent by the reporter which
    # contain information about the currently running (or soon to be) example group
    # It is used by formatters to access information about that group.
    #
    # @example
    #   def example_group_started(notification)
    #     puts "Hey I started #{notification.group.description}"
    #   end
    # @attr group [RSpec::Core::ExampleGroup] the current group
    GroupNotification = Struct.new(:group)

    # The `MessageNotification` encapsulates generic messages that the reporter
    # sends to formatters.
    #
    # @attr message [String] the message
    MessageNotification = Struct.new(:message)

    # The `SeedNotification` holds the seed used to randomize examples and
    # wether that seed has been used or not.
    #
    # @attr seed [Fixnum] the seed used to randomize ordering
    # @attr used [Boolean] wether the seed has been used or not
    SeedNotification = Struct.new(:seed, :used) do
      # @api
      # @return [Boolean] has the seed been used?
      def seed_used?
        !!used
      end
      private :used
    end

    # The `SummaryNotification` holds information about the results of running
    # a test suite. It is used by formatters to provide information at the end
    # of the test run.
    #
    # @attr duration [Float] the time taken (in seconds) to run the suite
    # @attr examples [Array(RSpec::Core::Example)] the examples run
    # @attr failed_examples [Array(RSpec::Core::Example)] the failed examples
    # @attr pending_examples [Array(RSpec::Core::Example)] the pending examples
    # @attr load_time [Float] the number of seconds taken to boot RSpec
    #                         and load the spec files
    SummaryNotification = Struct.new(:duration, :examples, :failed_examples, :pending_examples, :load_time) do

      # @api
      # @return [Fixnum] the number of examples run
      def example_count
        @example_count ||= examples.size
      end

      # @api
      # @return [Fixnum] the number of failed examples
      def failure_count
        @failure_count ||= failed_examples.size
      end

      # @api
      # @return [Fixnum] the number of pending examples
      def pending_count
        @pending_count ||= pending_examples.size
      end

      # @api
      # @return [String] A line summarising the results of the spec run.
      def summary_line
        summary = Formatters::Helpers.pluralize(example_count, "example")
        summary << ", " << Formatters::Helpers.pluralize(failure_count, "failure")
        summary << ", #{pending_count} pending" if pending_count > 0
        summary
      end

      # @api public
      #
      # Wraps the summary line with colors based on the configured
      # colors for failure, pending, and success. Defaults to red,
      # yellow, green accordingly.
      #
      # @param colorizer [#wrap] An object which supports wrapping text with
      #                          specific colors.
      # @return [String] A colorized summary line.
      def colorize_with(colorizer)
        if failure_count > 0
          colorizer.wrap(summary_line, RSpec.configuration.failure_color)
        elsif pending_count > 0
          colorizer.wrap(summary_line, RSpec.configuration.pending_color)
        else
          colorizer.wrap(summary_line, RSpec.configuration.success_color)
        end
      end

      # @return [String] a formatted version of the time it took to run the suite
      def formatted_duration
        Formatters::Helpers.format_duration(duration)
      end

      # @return [String] a formatted version of the time it took to boot RSpec and
      #   load the spec files
      def formatted_load_time
        Formatters::Helpers.format_duration(load_time)
      end
    end

    # The `DeprecationNotification` is issued by the reporter when a deprecated
    # part of RSpec is encountered. It represents information about the deprecated
    # call site.
    #
    # @attr message [String] A custom message about the deprecation
    # @attr deprecated [String] A custom message about the deprecation (alias of message)
    # @attr replacement [String] An optional replacement for the deprecation
    # @attr call_site [String] An optional call site from which the deprecation was issued
    DeprecationNotification = Struct.new(:deprecated, :message, :replacement, :call_site) do
      private_class_method :new

      # @api
      # Convenience way to initialize the notification
      def self.from_hash(data)
        new data[:deprecated], data[:message], data[:replacement], data[:call_site]
      end
    end

    # `NullNotification` represents a placeholder value for notifications that
    # currently require no information, but we may wish to extend in future.
    class NullNotification
    end

  end
end
