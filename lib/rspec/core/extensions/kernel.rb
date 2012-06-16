module Kernel
  unless defined?(debugger)
    # If not already defined by ruby-debug, this implementation prints helpful
    # message to STDERR when ruby-debug is not loaded.
    def debugger(*args)
      require 'rspec/core/debugger'
      ::RSpec::Core::Debugger.start(binding, caller[0])
    end 
  end
end

