if defined?(Cucumber)
  require 'shellwords'
  Before('~@with-clean-spec-opts') do
    set_environment_variable('SPEC_OPTS', "-r#{Shellwords.escape(__FILE__)}")
  end
else
  if ENV['REMOVE_OTHER_RSPEC_LIBS_FROM_LOAD_PATH']
    $LOAD_PATH.reject! { |x| /rspec-mocks/ === x || /rspec-expectations/ === x }
  end
end
