require 'rspec/core/formatters/helpers'
require 'rspec/core/formatters/base_formatter'
require 'stringio'

module RSpec
  module Core
    module Formatters

      # The `LegacyFormatter` is used to wrap older RSpec 2.x style formatters
      # for the new 3.x implementation. It takes care of registering all the
      # old notifications and translating them to the older formatter.
      #
      # @see RSpec::Core::Formatters::BaseFormatter
      class LegacyFormatter
        NOTIFICATIONS = %W[start message example_group_started example_group_finished example_started
                           example_passed example_failed example_pending start_dump dump_pending
                           dump_failures dump_summary seed close stop deprecation deprecation_summary]

        module LegacyInterface
          def self.our_formatters
            formatters = []
            formatters << BaseFormatter          if defined?(BaseFormatter)
            formatters << BaseTextFormatter      if defined?(BaseTextFormatter)
            formatters << DeprecationFormatter   if defined?(DeprecationFormatter)
            formatters << DocumentationFormatter if defined?(DocumentationFormatter)
            formatters << HtmlFormatter          if defined?(HtmlFormatter)
            formatters << JsonFormatter          if defined?(JsonFormatter)
            formatters << ProgressFormatter      if defined?(ProgressFormatter)
            formatters
          end

          def self.append_features(other)
            # stash the methods from the legacy formatter that conflict
            clashing_methods = (self.instance_methods & other.instance_methods).
                map    { |name| [name,other.instance_method(name)] }.
                reject { |name, meth| our_formatters.include? meth.owner }
            clashing_methods.each do |name, meth|
              meth.owner.__send__ :remove_method, name
            end

            # implement all of our methods
            super

            # restore the clashing methods on top of ours
            override_module = Module.new do
              class << self
                attr_accessor :__clashing_methods
              end
              def self.included(other)
                __clashing_methods.each do |(name, meth)|
                  other.send :define_method, name, meth
                end
              end
            end
            override_module.__clashing_methods = clashing_methods
            other.send :include, override_module
          end

          def start(count)
            super Notifications::CountNotification.new(count)
          end

          def example_group_started(group)
            super Notifications::GroupNotification.new(group) if defined?(super)
          end

          def example_group_finished(group)
            super Notifications::GroupNotification.new(group) if defined?(super)
          end

          def example_started(example)
            super Notifications::ExampleNotification.new(example) if defined?(super)
          end

          def example_passed(example)
            super Notifications::ExampleNotification.new(example) if defined?(super)
          end

          def example_pending(example)
            super Notifications::ExampleNotification.new(example) if defined?(super)
          end

          def example_failed(example)
            super Notifications::ExampleNotification.new(example) if defined?(super)
          end

          def message(message)
            super Notifications::MessageNotification.new(message) if defined?(super)
          end

          attr_reader :duration, :example_count, :failure_count, :pending_count
          def dump_summary(duration, examples, failures, pending)
            @duration      = duration
            @example_count = examples
            @failure_count = failures
            @pending_count = pending
            super Notifications::SummaryNotification.new(duration, examples, failures, pending) if defined?(super)
          end

          def seed(seed)
            super Notifications::SeedNotification.new(seed, true) if defined?(super)
          end


          def start_dump
            super(Notifications::NullNotification) if defined?(super)
          end

          def dump_failures
            super(Notifications::NullNotification) if defined?(super)
          end

          def dump_pending
            super(Notifications::NullNotification) if defined?(super)
          end

          def dump_profile
            super(Notifications::NullNotification) if defined?(super)
          end

          def close
            super(Notifications::NullNotification) if defined?(super)
          end

          def stop
            super(Notifications::NullNotification) if defined?(super)
          end

          def summary_line(example_count, failure_count, pending_count)
            summary = pluralize(example_count, "example")
            summary << ", " << pluralize(failure_count, "failure")
            summary << ", #{pending_count} pending" if pending_count > 0
            summary
          end

          def colorise_summary(summary)
            if failure_count > 0
              color(summary, RSpec.configuration.failure_color)
            elsif pending_count > 0
              color(summary, RSpec.configuration.pending_color)
            else
              color(summary, RSpec.configuration.success_color)
            end
          end
        end

        # @api private
        attr_reader :formatter

        # @api public
        #
        # @param formatter
        def initialize(formatter_class, *args)
          if formatter_class.ancestors.include?(BaseFormatter)
            formatter_class.class_eval do
              include LegacyInterface
            end
          end
          @formatter = formatter_class.new(*args)
        end

        # @api public
        #
        # This method is invoked during the setup phase to register
        # a formatters with the reporter
        #
        def notifications
          @notifications ||= NOTIFICATIONS.select { |m| @formatter.respond_to? m }
        end

        # @api public
        #
        # @param example_count
        def start(notification)
          @formatter.start notification.count
        end

        # @api public
        #
        # @param example_group
        def example_group_started(notification)
          @formatter.example_group_started notification.group
        end

        # @api public
        #
        # @param example_group
        def example_group_finished(notification)
          @formatter.example_group_finished notification.group
        end

        # @api public
        #
        # @param example
        def example_started(notification)
          @formatter.example_started notification.example
        end

        # @api public
        #
        # @param example
        def example_passed(notification)
          @formatter.example_passed notification.example
        end

        # @api public
        #
        # @param example
        def example_pending(notification)
          @formatter.example_pending notification.example
        end

        # @api public
        #
        # @param example
        def example_failed(notification)
          @formatter.example_failed notification.example
        end

        # @api public
        #
        # @param message
        def message(notification)
          @formatter.message notification.message
        end

        # @api public
        #
        def stop(notification)
          @formatter.stop
        end

        # @api public
        #
        def start_dump(notification)
          @formatter.start_dump
        end

        # @api public
        #
        def dump_failures(notification)
          @formatter.dump_failures
        end

        # @api public
        #
        # @param duration
        # @param example_count
        # @param failure_count
        # @param pending_count
        def dump_summary(summary)
          @formatter.dump_summary summary.duration, summary.example_count, summary.failure_count, summary.pending_count
        end

        # @api public
        #
        def dump_pending(notification)
          @formatter.dump_pending
        end

        # @api public
        #
        def dump_profile(notification)
          @formatter.dump_profile
        end

        # @api public
        #
        # @param seed
        def seed(notification)
          @formatter.seed notification.seed
        end

        # @api public
        #
        def close(notification)
          @formatter.close
        end

      end
    end
  end
end
