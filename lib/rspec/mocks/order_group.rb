module RSpec
  module Mocks
    # @private
    class OrderGroup
      def initialize
        @ordering = Array.new
      end

      # @private
      def register(expectation)
        @ordering << expectation
      end

      # @private
      def ready_for?(expectation)
        @ordering.first == expectation
      end

      # @private
      def consume
        @ordering.shift
      end

      # @private
      def handle_order_constraint expectation
        return unless @ordering.include? expectation
        return consume if ready_for?(expectation)
        expectation.raise_out_of_order_error
      end
    end
  end
end
