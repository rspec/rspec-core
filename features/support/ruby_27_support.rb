Around "@ruby-2-7" do |scenario, block|
  if RUBY_VERSION.to_f == 2.7
    block.call
  else
    skip_this_scenario "Skipping scenario #{scenario.name} on Ruby v#{RUBY_VERSION}"
  end
end
