RSpec::Support.require_rspec_support "directory_maker"

module RSpec
  module Core
    # @private
    class OutputWrapper
      # @private
      attr_reader :output

      # @private
      def initialize(io_or_file_path)
        @output = open_stream(io_or_file_path)
      end

      def output=(io_or_file_path)
        @output = open_stream(io_or_file_path)
      end

      # Redirect calls for IO interface methods
      IO.instance_methods(false).each do |method|
        define_method(method) do |*args, &block|
          output.send(method, *args, &block)
        end
      end

    private

      def open_stream(io_or_file_path)
        if io_or_file_path.respond_to?(:puts)
          io_or_file_path
        else
          RSpec::Support::DirectoryMaker.mkdir_p(File.dirname(io_or_file_path))
          File.open(io_or_file_path, 'w')
        end
      end
    end
  end
end
