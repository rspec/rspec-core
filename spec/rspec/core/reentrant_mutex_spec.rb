require 'rspec/core/reentrant_mutex'

# Monitor specs from stdlib
# https://github.com/ruby/ruby/blob/5b4afd028120c95b8dbf46a33f3b128f70df9293/test/monitor/test_monitor.rb

RSpec.describe RSpec::Core::ReentrantMutex do
  it 'is initially unlocked'
  it 'locks other threads that attempt to call it'
  it 'can be reentered by the thread with the lock'
  it 'does not release the lock until it has been unlocked the same number of times it was locked'
  it 'allows the next thread to obtain the lock upon release'
  it 'provides a #synchronize method for convenience, which locks, executes, and unlocks'
end
