require 'rspec/mocks/any_instance/chain'
require 'rspec/mocks/any_instance/stub_chain'
require 'rspec/mocks/any_instance/stub_chain_chain'
require 'rspec/mocks/any_instance/expectation_chain'
require 'rspec/mocks/any_instance/message_chains'
require 'rspec/mocks/any_instance/recorder'

module RSpec
  module Mocks
    module AnyInstance
      def any_instance
        RSpec::Mocks::space.add(self)
        __recorder
      end
      
      def rspec_verify
        __recorder.verify
        super
      ensure
        __recorder.stop_all_observation!
        @__recorder = nil
      end

      def __recorder
        @__recorder ||= AnyInstance::Recorder.new(self)
      end
    end
  end
end
