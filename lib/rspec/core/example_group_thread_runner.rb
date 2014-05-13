module RSpec
  module Core
    class ExampleGroupThreadRunner
      attr_accessor :thread_array

      def initialize
        @thread_array = []
      end

      def run(examplegroup, reporter, num_threads=1)
        @thread_array.push Thread.start {
          # puts "Starting examplegroup '#{examplegroup.description}'..."
          examplegroup.run(reporter, num_threads)
          # puts "Examplegroup '#{examplegroup.description}' completed."
          @thread_array.delete Thread.current # remove from local scope
        }
      end

      # Method will wait for all threads to complete.  On completion threads
      # remove themselves from the @thread_array so an empty array means they
      # completed
      def wait_for_completion
        # wait for threads to complete
        while @thread_array.length > 0
          # puts "Waiting for #{@thread_array.length} group threads to complete."
          sleep 1 #0.1
        end
      end
    end
  end
end