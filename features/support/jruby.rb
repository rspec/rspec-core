Around "@broken-on-jruby-9000" do |scenario, block|
  require 'rspec/support/ruby_features'
  if RSpec::Support::Ruby.jruby_9000?
    skip_this_scenario "Skipping scenario #{scenario.name} not supported on JRuby 9000"
  else
    block.call
  end
end

Around "@broken-on-jruby" do |scenario, block|
  require 'rspec/support/ruby_features'
  if RSpec::Support::Ruby.jruby?
    skip_this_scenario "Skipping scenario #{scenario.name} not supported on JRuby"
  else
    block.call
  end
end
