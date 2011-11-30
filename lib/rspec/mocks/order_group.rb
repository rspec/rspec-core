module RSpec
  module Mocks
    # @private
    class OrderGroup
      def initialize error_generator
        @error_generator = error_generator
        @ordering = Array.new
      end

      # @private
      def register(expectation)
        @ordering << expectation
      end

      # @private
      def ready_for?(expectation)
        return @ordering.first == expectation
      end

      # @private
      def consume
        @ordering.shift
      end

      # @private
      def handle_order_constraint expectation
        return unless @ordering.include? expectation
        return consume if ready_for?(expectation)
        @error_generator.raise_out_of_order_error expectation.sym
      end
    end
  end
end
