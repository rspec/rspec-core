# Intermidiate autoloading file as described here
# https://stackoverflow.com/a/54602185/1299362
module RSpec
  module Core
    module DidYouMean
      autoload :Proximity, 'rspec/core/did_you_mean/proximity'
      autoload :Suggestions, 'rspec/core/did_you_mean/suggestions'
    end
  end
end
