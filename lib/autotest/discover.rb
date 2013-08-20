if File.exist?("./.rspec")
  Autotest.add_discovery { "rspec2" }
else
  warn "RSpec Autotest integration was attempted, but no `.rspec` file was present. Assuming RSpec not loaded."
end
