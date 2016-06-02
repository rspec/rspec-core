Given(/^only rspec-core is installed$/) do
  set_env('RUBYOPT', ENV['RUBYOPT'] + ' --disable-gems')

  # This will make `require_expect_syntax_in_aruba_specs.rb` (loaded
  # automatically when the specs run) remove rspec-mocks and
  # rspec-expectations from the load path.
  set_env('REMOVE_OTHER_RSPEC_LIBS_FROM_LOAD_PATH', 'true')
end

Given(/^rspec-expectations is not installed$/) do
  step "only rspec-core is installed"
end
