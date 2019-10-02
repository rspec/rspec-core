require 'rubygems' if RUBY_VERSION.to_f < 1.9

require 'rspec/support/spec'

$rspec_core_without_stderr_monkey_patch = RSpec::Core::Configuration.new

class RSpec::Core::Configuration
  def self.new(*args, &block)
    super.tap do |config|
      # We detect ruby warnings via $stderr,
      # so direct our deprecations to $stdout instead.
      config.deprecation_stream = $stdout
    end
  end
end

Dir['./spec/support/**/*.rb'].map do |file|
  # fake libs aren't intended to be loaded except by some specific specs
  # that shell out and run a new process.
  next if file =~ /fake_libs/

  # Ensure requires are relative to `spec`, which is on the
  # load path. This helps prevent double requires on 1.8.7.
  require file.gsub("./spec/support", "support")
end

class RaiseOnFailuresReporter < RSpec::Core::NullReporter
  def self.example_failed(example)
    raise example.exception
  end
end

module CommonHelpers
  def describe_successfully(*args, &describe_body)
    example_group    = RSpec.describe(*args, &describe_body)
    ran_successfully = example_group.run RaiseOnFailuresReporter
    expect(ran_successfully).to eq true
    example_group
  end

  def with_env_vars(vars)
    original = ENV.to_hash
    vars.each { |k, v| ENV[k] = v }

    begin
      yield
    ensure
      ENV.replace(original)
    end
  end

  def without_env_vars(*vars)
    original = ENV.to_hash
    vars.each { |k| ENV.delete(k) }

    begin
      yield
    ensure
      ENV.replace(original)
    end
  end

  def handle_current_dir_change
    RSpec::Core::Metadata.instance_variable_set(:@relative_path_regex, nil)
    yield
  ensure
    RSpec::Core::Metadata.instance_variable_set(:@relative_path_regex, nil)
  end

  def dedent(string)
    string.gsub(/^\s+\|/, '').chomp
  end

  # We have to use Hash#inspect in examples that have multi-entry
  # hashes because the #inspect output on 1.8.7 is non-deterministic
  # due to the fact that hashes are not ordered. So we can't simply
  # put a literal string for what we expect because it varies.
  if RUBY_VERSION.to_f == 1.8
    def hash_inspect(hash)
      "\\{(#{hash.map { |key, value| "#{key.inspect} => #{value.inspect}.*" }.join "|"}){#{hash.size}}\\}"
    end
  else
    def hash_inspect(hash)
      RSpec::Matchers::BuiltIn::BaseMatcher::HashFormatting.
        improve_hash_formatting hash.inspect
    end
  end
end

RSpec.configure do |c|
  c.example_status_persistence_file_path = "./spec/examples.txt"
  c.around(:example, :isolated_directory) do |ex|
    handle_current_dir_change(&ex)
  end

  # structural
  c.alias_it_behaves_like_to 'it_has_behavior'
  c.include(RSpecHelpers)
  c.disable_monkey_patching!

  # runtime options
  c.raise_errors_for_deprecations!
  c.color = true
  c.include CommonHelpers

  c.expect_with :rspec do |expectations|
    $default_expectation_syntax = expectations.syntax # rubocop:disable Style/GlobalVars
    expectations.syntax = :expect
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  c.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  c.around(:example, :simulate_shell_allowing_unquoted_ids) do |ex|
    with_env_vars('SHELL' => '/usr/local/bin/bash', &ex)
  end

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

  $original_rspec_configuration = c
end

RSpec.shared_context "with #should enabled", :uses_should do
  orig_syntax = nil

  before(:all) do
    orig_syntax = RSpec::Matchers.configuration.syntax
    RSpec::Matchers.configuration.syntax = [:expect, :should]
  end

  after(:context) do
    RSpec::Matchers.configuration.syntax = orig_syntax
  end
end

RSpec.shared_context "with the default expectation syntax" do
  orig_syntax = nil

  before(:context) do
    orig_syntax = RSpec::Matchers.configuration.syntax
    RSpec::Matchers.configuration.reset_syntaxes_to_default
  end

  after(:context) do
    RSpec::Matchers.configuration.syntax = orig_syntax
  end

end

RSpec.shared_context "with #should exclusively enabled", :uses_only_should do
  orig_syntax = nil

  before(:context) do
    orig_syntax = RSpec::Matchers.configuration.syntax
    RSpec::Matchers.configuration.syntax = :should
  end

  after(:context) do
    RSpec::Matchers.configuration.syntax = orig_syntax
  end
end

RSpec.shared_context "isolate include_chain_clauses_in_custom_matcher_descriptions" do
  around do |ex|
    orig = RSpec::Expectations.configuration.include_chain_clauses_in_custom_matcher_descriptions?
    ex.run
    RSpec::Expectations.configuration.include_chain_clauses_in_custom_matcher_descriptions = orig
  end
end

RSpec.shared_context "with warn_about_potential_false_positives set to false", :warn_about_potential_false_positives do
  original_value = RSpec::Expectations.configuration.warn_about_potential_false_positives?

  after(:context)  { RSpec::Expectations.configuration.warn_about_potential_false_positives = original_value }
end

module MinitestIntegration
  include ::RSpec::Support::InSubProcess

  def with_minitest_loaded
    in_sub_process do
      with_isolated_stderr do
        require 'minitest/autorun'
      end

      require 'rspec/expectations/minitest_integration'
      yield
    end
  end
end

RSpec::Matchers.define_negated_matcher :avoid_outputting, :output
