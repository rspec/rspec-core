Before "@ruby-2-7" do |scenario|
  unless RUBY_VERSION.to_f == 2.7
    warn "Skipping scenario #{scenario.title} on Ruby v#{RUBY_VERSION}"
    skip_this_scenario
  end
end
