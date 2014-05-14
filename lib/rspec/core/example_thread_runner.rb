module RSpec
  module Core
    class ExampleThreadRunner
      attr_accessor :num_threads, :thread_array

      def initialize(num_threads)
        @num_threads = num_threads # used to track the local usage of threads
        @thread_array = []
        $used_threads = $used_threads || 0 # used to track the global usage of threads
      end

      # Method will check global utilization of threads and if that number is
      # at or over the allocated maximum it will wait until a thread is available
      def wait_for_available_thread
        # wait for available thread if we've reached our global limit
        while $used_threads.to_i >= @num_threads.to_i
          sleep 1
        end
      end

      # Method will run the specified example within an available thread or
      # will wait for a thread to become available if none currently are
      def run(example, instance, reporter)
        wait_for_available_thread
        @thread_array.push Thread.start {
          example.run(instance, reporter)
          @thread_array.delete Thread.current # remove from local scope
          $used_threads -= 1 # remove from global scope
        }
        $used_threads += 1 # add to global scope
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