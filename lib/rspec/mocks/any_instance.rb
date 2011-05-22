require 'rspec/mocks/any_instance/recorder'
require 'rspec/mocks/any_instance/player'
require 'rspec/mocks/any_instance/chains'
require 'rspec/mocks/any_instance/message'
require 'rspec/mocks/any_instance/chain'
require 'rspec/mocks/any_instance/expectation'
require 'rspec/mocks/any_instance/stub'

module RSpec
  module Mocks
    module AnyInstance

      def any_instance
        Mocks.space.add(self)
        __recorder
      end

      def rspec_verify
        __recorder.verify
        super
      ensure
        __recorder.remove_chains
        @__recorder = nil
      end

      def __recorder
        @__recorder ||= Recorder.new(self)
      end
      
    end
  end
end
