require 'rubygems'
require 'spork'

Spork.prefork do
  require 'rspec/core'
  require 'autotest/rspec2'

  Dir['./spec/support/**/*.rb'].map {|f| require f}

  class NullObject
    private
    def method_missing(method, *args, &block)
      # ignore
    end
  end

  def sandboxed(&block)
    begin
      @orig_config = RSpec.configuration
      @orig_world  = RSpec.world
      new_config = RSpec::Core::Configuration.new
      new_world  = RSpec::Core::World.new(new_config)
      RSpec.instance_variable_set(:@configuration, new_config)
      RSpec.instance_variable_set(:@world, new_world)
      object = Object.new
      object.extend(RSpec::Core::SharedExampleGroup)

      (class << RSpec::Core::ExampleGroup; self; end).class_eval do
        alias_method :orig_run, :run
        def run(reporter=nil)
          @orig_mock_space = RSpec::Mocks::space
          RSpec::Mocks::space = RSpec::Mocks::Space.new
          orig_run(reporter || NullObject.new)
        ensure
          RSpec::Mocks::space = @orig_mock_space
        end
      end

      object.instance_eval(&block)
  ensure
    (class << RSpec::Core::ExampleGroup; self; end).class_eval do
      remove_method :run
      alias_method :run, :orig_run
      remove_method :orig_run
    end

    RSpec.instance_variable_set(:@configuration, @orig_config)
    RSpec.instance_variable_set(:@world, @orig_world)
end
end

def in_editor?
  ENV.has_key?('TM_MODE') || ENV.has_key?('EMACS') || ENV.has_key?('VIM')
end

RSpec.configure do |c|
  c.color_enabled = !in_editor?
  c.filter_run :focus => true
  c.run_all_when_everything_filtered = true
  c.filter_run_excluding :ruby => lambda {|version|
    case version.to_s
    when "!jruby"
      RUBY_ENGINE == "jruby"
    when /^> (.*)/
      !(RUBY_VERSION.to_s > $1)
    else
      !(RUBY_VERSION.to_s =~ /^#{version.to_s}/)
    end
  }
  c.alias_it_should_behave_like_to 'it_has_behavior'
  c.around do |example|
    sandboxed { example.run }
  end
end
end

Spork.each_run do
end

