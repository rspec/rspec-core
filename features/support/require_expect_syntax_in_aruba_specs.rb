if defined?(Cucumber)
  require 'shellwords'
  exclude_allow_should_syntax = 'not @allow-should-syntax'
  exclude_with_clean_spec_ops = 'not @with-clean-spec-opts'
  Before(exclude_allow_should_syntax, exclude_with_clean_spec_ops) do
    set_environment_variable('SPEC_OPTS', "-r#{Shellwords.escape(__FILE__)}")
  end
else
  if ENV['REMOVE_OTHER_RSPEC_LIBS_FROM_LOAD_PATH']
    $LOAD_PATH.reject! { |x| /rspec-mocks/ === x || /rspec-expectations/ === x }
  end
end
