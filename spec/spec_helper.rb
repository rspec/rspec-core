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

  require file
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
end

RSpec.configure do |c|
  c.example_status_persistence_file_path = "./spec/examples.txt"
  c.around(:example, :isolated_directory) do |ex|
    handle_current_dir_change(&ex)
  end

  # structural
  c.alias_it_behaves_like_to 'it_has_behavior'
  c.include(RSpecHelpers)

  # runtime options
  c.raise_errors_for_deprecations!
  c.color = true
  c.include CommonHelpers

  c.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
    expectations.max_formatted_output_length = 1000
  end

  c.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  c.around(:example, :simulate_shell_allowing_unquoted_ids) do |ex|
    with_env_vars('SHELL' => '/usr/local/bin/bash', &ex)
  end
end
