require 'spec_helper'

module Rspec
  module Mocks

    # We expect our original method to be stashed like this:
    #
    # class Rspec::Mocks::FooBar
    #   def self.foo(*args, &block)
    #     __mock_proxy.message_received(:foo, *args, &block)
    #   end
    #
    #   def self.obfuscated_by_rspec_mocks__foo(arg)
    #     :original_value
    #   end
    # end

    # Yet, we end up with the proxy method being stashed when multiple
    # expectations are added to the same method:
    #
    # class Rspec::Mocks::FooBar
    #   def self.foo(*args, &block)
    #     __mock_proxy.message_received(:foo, *args, &block)
    #   end
    #
    #   def self.obfuscated_by_rspec_mocks__foo(*args, &block)
    #     __mock_proxy.message_received(:foo, *args, &block)
    #   end
    # end

    class FooBar
      def self.foo(arg)
        :original_value
      end
    end

    describe "only stashing the original method" do
      # Fix to avoid stashing the proxy method once the original method has already been stashed.
      # Having multiple stubs or expectations on the same method would result in the
      # original method being completely lost if it did not check if it was already stashed.
      it "should keep the original method intact after multiple expectations are added on the same method" do
        FooBar.should_receive(:foo).with(:fizbaz).and_return(:wowwow)
        FooBar.should_receive(:foo).with(:bazbar).and_return(:okay)

        FooBar.foo(:fizbaz)
        FooBar.foo(:bazbar)
        FooBar.rspec_verify

        FooBar.rspec_reset
        FooBar.foo(:yeah).should equal(:original_value)
      end
    end
  end
end