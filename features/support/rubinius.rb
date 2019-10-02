# Required until https://github.com/rubinius/rubinius/issues/2430 is resolved
ENV['RBXOPT'] = "#{ENV["RBXOPT"]} -Xcompiler.no_rbc"

<<<<<<< HEAD
Around "@unsupported-on-rbx" do |scenario, block|
=======
Around "@unsupported-on-rbx" do |_scenario, block|
>>>>>>> rspec-expectations/master
  block.call unless defined?(Rubinius)
end
