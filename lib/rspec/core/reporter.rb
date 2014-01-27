module RSpec::Core
  class Reporter

    def initialize(configuration)
      @configuration = configuration
      @listeners = Hash.new { |h,k| h[k] = Set.new }
      @example_count = @failure_count = @pending_count = 0
      @duration = @start = nil
    end

    # @api
    # @param [Object] An obect that wishes to be notified of reporter events
    # @param [Array] Array of symbols represents the events a listener wishes to subscribe too
    #
    # Registers a listener to a list of notifications. The reporter will send notification of
    # events to all registered listeners
    def register_listener(listener, *notifications)
      notifications.each do |notification|
        @listeners[notification.to_sym] << listener
      end
      true
    end

    def registered_listeners(notification)
      @listeners[notification].to_a
    end

    # @api
    # @overload report(count, &block)
    # @overload report(count, &block)
    # @param [Integer] count the number of examples being run
    # @param [Block] block yields itself for further reporting.
    #
    # Initializes the report run and yields itself for further reporting. The
    # block is required, so that the reporter can manage cleaning up after the
    # run.
    #
    # @example
    #
    #     reporter.report(group.examples.size) do |r|
    #       example_groups.map {|g| g.run(r) }
    #     end
    #
    def report(expected_example_count)
      start(expected_example_count)
      begin
        yield self
      ensure
        finish
      end
    end

    def start(expected_example_count)
      @start = RSpec::Core::Time.now
      notify :start, CountNotification.new(expected_example_count)
    end

    def message(message)
      notify :message, MessageNotification.new(message)
    end

    def example_group_started(group)
      notify :example_group_started, GroupNotification.new(group) unless group.descendant_filtered_examples.empty?
    end

    def example_group_finished(group)
      notify :example_group_finished, GroupNotification.new(group) unless group.descendant_filtered_examples.empty?
    end

    def example_started(example)
      @example_count += 1
      notify :example_started, ExampleNotification.new(example)
    end

    def example_passed(example)
      notify :example_passed, ExampleNotification.new(example)
    end

    def example_failed(example)
      @failure_count += 1
      notify :example_failed, ExampleNotification.new(example)
    end

    def example_pending(example)
      @pending_count += 1
      notify :example_pending, ExampleNotification.new(example)
    end

    def deprecation(hash)
      notify :deprecation, DeprecationNotification.from_hash(hash)
    end

    def finish
      begin
        stop
        notify :start_dump,    NullNotification.instance
        notify :dump_pending,  NullNotification.instance
        notify :dump_failures, NullNotification.instance
        notify :dump_summary, SummaryNotification.new(@duration, @example_count, @failure_count, @pending_count)
        notify :deprecation_summary, NullNotification.instance
        notify :seed, SeedNotification.new(@configuration.seed, seed_used?)
      ensure
        notify :close, NullNotification.instance
      end
    end

    def stop
      @duration = (RSpec::Core::Time.now - @start).to_f if @start
      notify :stop, NullNotification.instance
    end

    def notify(event, notification)
      registered_listeners(event).each do |formatter|
        formatter.__send__(event, notification)
      end
    end

  private

    def seed_used?
      @configuration.seed && @configuration.seed_used?
    end
  end
end
