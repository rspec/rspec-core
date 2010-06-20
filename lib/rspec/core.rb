module RSpec
  class << self
    def subscriptions
      @subscriptions ||= Hash.new {|h,k| h[k] = []}
    end

    # Supported events:
    #   example_group_started
    #   example_started
    #   example_initialized
    #   example_executed
    #   example_finished
    def subscribe(event, &callback)
      subscriptions[event] << callback
    end

    def publish(event, *args)
      subscriptions[event].each {|callback| callback.call(*args)}
    end
    def world
      @world ||= RSpec::Core::World.new
    end

    def configuration
      @configuration ||= RSpec::Core::Configuration.new
    end

    def configure
      yield configuration if block_given?
    end
  end
end

require 'rspec/core/kernel_extensions'
require 'rspec/core/object_extensions'
require 'rspec/core/load_path'
require 'rspec/core/deprecation'
require 'rspec/core/formatters'

require 'rspec/core/hooks'
require 'rspec/core/subject'
require 'rspec/core/let'
require 'rspec/core/metadata'
require 'rspec/core/pending'

require 'rspec/core/around_proxy'
require 'rspec/core/world'
require 'rspec/core/notifier'
require 'rspec/core/configuration'
require 'rspec/core/option_parser'
require 'rspec/core/configuration_options'
require 'rspec/core/command_line'
require 'rspec/core/drb_command_line'
require 'rspec/core/runner'
require 'rspec/core/example'
require 'rspec/core/shared_example_group'
require 'rspec/core/example_group'
require 'rspec/core/version'
require 'rspec/core/errors'
require 'rspec/core/backward_compatibility'

# TODO - make this configurable with default 'on'
require 'rspec/expectations'

require 'rspec/monkey'
