module RSpec
  module Core
    class ExampleThreadRunner
      attr_accessor :num_threads, :thread_array, :fname, :lock

      def initialize(num_threads)
        @num_threads = num_threads # used to track the local usage of threads
        # puts "Creating ExampleThreadRunner object with #{@num_threads} threads."
        @thread_array = []
        $used_threads = $used_threads || 0 # used to track the global usage of threads
        @fname = '.examplelock'
        if !File.exists? @fname
          File.new(@fname, "a+") { |f| f.write "lock" }
        end
      end

      # Method will check global utilization of threads and if that number is
      # at or over the allocated maximum it will wait until a thread is available
      def wait_for_available_thread
        # puts "Global threads in use = #{$used_threads}."
        # puts "Local threads in use = #{@thread_array.length}."
        # wait for available thread if we've reached our global limit
        while $used_threads.to_i >= @num_threads.to_i
          # puts "Waiting for available thread. Running = #{$used_threads}; Max = #{@num_threads}"
          sleep 1 #0.1
        end
      end

      # Method will run the specified example within an available thread or
      # will wait for a thread to become available if none currently are
      def run(example, instance, reporter)
        # puts "Setting lock for example '#{example.description}'..."
        set_lock
        wait_for_available_thread
        @thread_array.push Thread.start {
          # puts "Starting example '#{example.description}'..."
          example.run(instance, reporter)
          # puts "Example '#{example.description}' completed."
          @thread_array.delete Thread.current # remove from local scope
          $used_threads -= 1 # remove from global scope
        }
        $used_threads += 1 # add to global scope
      ensure
        # puts "Releasing lock for example '#{example.description}'..."
        release_lock
        # puts "Lock for '#{example.description}' released."
      end

      # Method will wait for all threads to complete.  On completion threads
      # remove themselves from the @thread_array so an empty array means they
      # completed
      def wait_for_completion
        # wait for threads to complete
        while @thread_array.length > 0
          # puts "Waiting for #{@thread_array.length} example threads to complete."
          sleep 1 #0.1
        end
      end

      # Method creates a file based mutex to prevent problems due to parallel
      # access to a global / shared value
      def set_lock
        (@lock = File.new(@fname,"r+")).flock(File::LOCK_EX)
      end

      # Method releases the file based mutex
      def release_lock
        @lock.flock(File::LOCK_UN)
      end
    end
  end
end