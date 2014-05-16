module RSpec
  module Core
    # ExampleThreadRunner is a class used to execute [Example] classes in
    # parallel as part of rspec-core.  When running in parallel the order
    # of examples will not be honoured.  
    # This class is used to ensure that we have a way of keeping track of
    # the number of threads being created and preventing utilization of
    # more than the specified number
    class ExampleThreadRunner
      attr_accessor :num_threads, :thread_array, :used_threads

      # Creates a new instance of ExampleThreadRunner.
      # @param num_threads [Integer] the maximum limit of threads that can be used
      # @param used_threads [Integer] the current number of threads being used
      def initialize(num_threads, used_threads)
        @num_threads = num_threads
        @thread_array = []
        @used_threads = used_threads
      end

      # Method will check global utilization of threads and if that number is
      # at or over the allocated maximum it will wait until a thread is available
      def wait_for_available_thread
        while @used_threads.to_i >= @num_threads.to_i
          sleep 0.1
        end
      end

      # Method will run the specified example within an available thread or
      # will wait for a thread to become available if none currently are
      # @param example [Example] the example to be executed in a [Thread]
      # @param instance the instance of an ExampleGroup subclass
      # @param reporter [Reporter] the passed in reporting class used for 
      # tracking
      def run(example, instance, reporter)
        wait_for_available_thread
        @thread_array.push Thread.start { 
          example.run(instance, reporter)
          @thread_array.delete Thread.current # remove from local scope
          @used_threads -= 1
        }
        @used_threads += 1
      end

      # Method will wait for all threads to complete.  On completion threads
      # remove themselves from the @thread_array so an empty array means they
      # completed
      def wait_for_completion
        @thread_array.each do |t|
          t.join
        end
      end
    end
  end
end
