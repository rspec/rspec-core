require 'aruba/cucumber'

Before do
  # Force ids to be printed unquoted for consistency
  set_environment_variable('SHELL', '/usr/bin/bash')
end

Aruba.configure do |config|
  config.exit_timeout = if RUBY_PLATFORM =~ /java/ || defined?(Rubinius) || (defined?(RUBY_ENGINE) && RUBY_ENGINE == 'truffleruby')
    120
  else
    10
  end
end

Aruba.configure do |config|
  config.before(:command) do |cmd|
    set_environment_variable('JRUBY_OPTS', "-X-C #{ENV['JRUBY_OPTS']}") # disable JIT since these processes are so short lived
  end
end if RUBY_PLATFORM == 'java'

Aruba.configure do |config|
  config.before(:command) do |cmd|
    set_environment_variable('RBXOPT', "-Xint=true #{ENV['RBXOPT']}") # disable JIT since these processes are so short lived
  end
end if defined?(Rubinius)

module ArubaHelpers
  def all_output
    all_commands.map { |c| c.output }.join("\n")
  end
end

World(ArubaHelpers)
