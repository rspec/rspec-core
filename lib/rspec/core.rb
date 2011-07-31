require 'rspec/core/dsl'
require 'rspec/core/extensions'
require 'rspec/core/load_path'
require 'rspec/core/deprecation'
require 'rspec/core/backward_compatibility'
require 'rspec/core/reporter'

require 'rspec/core/metadata_hash_builder'
require 'rspec/core/hooks'
require 'rspec/core/subject'
require 'rspec/core/let'
require 'rspec/core/metadata'
require 'rspec/core/pending'

require 'rspec/core/world'
require 'rspec/core/configuration'
require 'rspec/core/command_line_configuration'
require 'rspec/core/option_parser'
require 'rspec/core/configuration_options'
require 'rspec/core/command_line'
require 'rspec/core/drb_command_line'
require 'rspec/core/runner'
require 'rspec/core/example'
require 'rspec/core/shared_context'
require 'rspec/core/shared_example_group'
require 'rspec/core/example_group'
require 'rspec/core/version'
require 'rspec/core/errors'

require 'rspec/autorun' if $0.split(File::SEPARATOR).last == 'rcov'

module RSpec
  autoload :Matchers, 'rspec/matchers'

  SharedContext = Core::SharedContext

  module Core
    def self.install_directory
      @install_directory ||= File.expand_path(File.dirname(__FILE__))
    end
  end

  # Used internally to determine what to do when a SIGINT is received
  def self.wants_to_quit
    world.wants_to_quit
  end

  # Used internally to determine what to do when a SIGINT is received
  def self.wants_to_quit=(maybe)
    world.wants_to_quit=(maybe)
  end

  # Internal container for global non-configuration data
  def self.world
    @world ||= RSpec::Core::World.new
  end

  # Used internally to ensure examples get reloaded between multiple runs in
  # the same process.
  def self.reset
    world.reset
    configuration.reset
  end

  # Returns the global configuration object
  def self.configuration
    @configuration ||= RSpec::Core::Configuration.new
  end

  # Yields the global configuration object
  #
  # == Examples
  #
  # RSpec.configure do |config|
  #   config.format = 'documentation'
  # end
  def self.configure
    yield configuration if block_given?
  end

  # Used internally to clear remaining groups when fail_fast is set
  def self.clear_remaining_example_groups
    world.example_groups.clear
  end
end

require 'rspec/core/backward_compatibility'
require 'rspec/monkey'
