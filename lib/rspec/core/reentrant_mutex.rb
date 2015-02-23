# These need to go away, we don't want to depend on stdlib
require 'thread'
require 'monitor' # reentrant mutex from stdlib

module RSpec
  module Core
    # Allows a thread to lock out other threads from a critical section of code,
    # while allowing the thread with the lock to reenter that section.
    #
    # Monitor as of 2.2 - https://github.com/ruby/ruby/blob/eb7ddaa3a47bf48045d26c72eb0f263a53524ebc/lib/monitor.rb#L9
    # Mutex was moved from stdlib's thread.rb into core as of 1.9.1, based on docs
    #   exists - http://ruby-doc.org/core-1.9.1/Mutex.html
    #   dne    - http://ruby-doc.org/core-1.9.0/Mutex.html
    class ReentrantMutex
      def initialize
        @monitor = ::Monitor.new
      end

      def synchronize
        @monitor.synchronize { yield }
      end
    end
  end
end
