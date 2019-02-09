module RSpec
  module Core
    # Intermediate auto-loading file
    module DidYouMean
      autoload :Proximity, 'rspec/core/did_you_mean/proximity'
      autoload :Suggestions, 'rspec/core/did_you_mean/suggestions'
    end
  end
end
