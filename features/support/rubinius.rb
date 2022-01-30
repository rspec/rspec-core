# Required until https://github.com/rubinius/rubinius/issues/2430 is resolved
ENV['RBXOPT'] = "#{ENV["RBXOPT"]} -Xcompiler.no_rbc"

Around "@unsupported-on-rbx" do |scenario, block|
  if defined?(Rubinius)
    block.call
  else
    skip_this_scenario "Skipping scenario #{scenario.name} not supported on Rubinius"
  end
end
