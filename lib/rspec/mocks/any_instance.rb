require 'rspec/mocks/any_instance/chain'
require 'rspec/mocks/any_instance/message_chains'
require 'rspec/mocks/any_instance/recorder'

module RSpec
  module Mocks
    module AnyInstance
      # Used to set stubs and message expectations on any instance of a given
      # class. Returns a [Recorder](Recorder), which records messages like
      # `stub` and `should_receive` for later playback on instances of the
      # class.
      #
      # @example
      #
      #     Car.any_instance.should_receive(:go)
      #     race = Race.new
      #     race.cars << Car.new
      #     race.go # assuming this delegates to all of its cars
      #             # this example would pass
      #
      #     Account.any_instance.stub(:balance) { Money.new(:USD, 25) }
      #     Account.new.balance # => Money.new(:USD, 25))
      #
      # @return [Recorder]
      def any_instance
        RSpec::Mocks::space.add(self)
        __recorder
      end
      
      # @private
      def rspec_verify
        __recorder.verify
        super
      ensure
        __recorder.stop_all_observation!
        @__recorder = nil
      end

      # @private
      def __recorder
        @__recorder ||= AnyInstance::Recorder.new(self)
      end
    end
  end
end
