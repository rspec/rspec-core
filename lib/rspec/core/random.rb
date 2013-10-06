module RSpec
  module Core
    if defined?(Kernel::Random)
      Random = Kernel::Random
    else
      require 'rspec/core/random/backport_random'
    end
  end
end
