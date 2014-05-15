module RSpec
  module Core
    class ExampleGroupThreadRunner
      attr_accessor :thread_array, :max_threads, :mutex, :used_threads

      def initialize(max_threads = 1, mutex = Mutex.new, used_threads = 0)
        @max_threads = max_threads
        @mutex = mutex
        @used_threads = used_threads
        @thread_array = []
      end

      # Method will run an [ExampleGroup] inside a [Thread] to prevent blocking
      # execution.  The new [Thread] is added to an array for tracking and
      # will automatically remove itself when done
      def run(examplegroup, reporter)
        @thread_array.push Thread.start {
          examplegroup.run_parallel(reporter, @max_threads, @mutex, @used_threads)
          @thread_array.delete Thread.current
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
