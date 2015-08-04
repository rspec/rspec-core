require 'aruba/cucumber'

Before do
  # Force ids to be printed unquoted for consistency
  set_environment_variable('SHELL', '/usr/bin/bash')

  if RUBY_PLATFORM =~ /java/ || defined?(Rubinius)
    @aruba_timeout_seconds = 60
  else
    @aruba_timeout_seconds = 10
  end
end

Aruba.configure do |config|
  config.before_cmd do |cmd|
    prepend_environment_variable('JRUBY_OPTS', "-X-C ") # disable JIT since these processes are so short lived
  end
end if RUBY_PLATFORM == 'java'

Aruba.configure do |config|
  config.before_cmd do |cmd|
    prepend_environment_variable('RBXOPT', "-Xint=true ") # disable JIT since these processes are so short lived
  end
end if defined?(Rubinius)
