module RSpec
  module Core
    class ExampleGroupThreadRunner
      attr_accessor :thread_array

      def initialize
        @thread_array = []
      end

      # Method will run an [ExampleGroup] inside a [Thread] to prevent blocking
      # execution.  The new [Thread] is added to an array for tracking and
      # will automatically remove itself when done
      def run(examplegroup, reporter, num_threads = 1)
        @thread_array.push Thread.start {
          examplegroup.run(reporter, num_threads)
          @thread_array.delete Thread.current # remove from local scope
        }
      end

      # Method will wait for all threads to complete.  On completion threads
      # remove themselves from the @thread_array so an empty array means they
      # completed
      def wait_for_completion
        while @thread_array.length > 0
          sleep 1
        end
      end
    end
  end
end