module RSpec
  module Core
    if defined?(::Random)
      Random = ::Random
    else
      require 'rspec/core/random/backport_random'
    end
  end
end
