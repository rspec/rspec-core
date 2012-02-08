module RSpec
  module Mocks
    # @api private
    class Space
      def add(obj)
        mocks << obj unless mocks.detect {|m| m.equal? obj}
      end

      def verify_all
        mocks.each do |mock|
          mock.rspec_verify
        end
      end

      def reset_all
        mocks.each do |mock|
          mock.rspec_reset
        end
        mocks.clear
        expectation_ordering.clear
      end

      def expectation_ordering
        @expectation_ordering ||= OrderGroup.new
      end

    private
    
      def mocks
        @mocks ||= []
      end

    end
  end
end
