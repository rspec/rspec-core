module RSpec
  module Core
    # @private
    module FlatMap
      def flat_map(array, &block)
        array.flat_map(&block)
      end

      module_function :flat_map
    end
  end
end
