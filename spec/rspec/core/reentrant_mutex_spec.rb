require 'rspec/core/reentrant_mutex'

# There are no assertions specifically
# They are pass if they don't deadlock
RSpec.describe RSpec::Core::ReentrantMutex do
  let!(:mutex) { described_class.new }
  let!(:order) { ThreadOrderSupport.new }
  after { order.apocalypse! }

  it 'can repeatedly synchronize within the same thread' do
    mutex.synchronize { mutex.synchronize { } }
  end

  it 'locks other threads out while in the synchronize block' do
    order.declare(:before) { mutex.synchronize { } }
    order.declare(:within) { mutex.synchronize { } }
    order.declare(:after)  { mutex.synchronize { } }

    order.pass_to :before, :resume_on => :exit
    mutex.synchronize { order.pass_to :before, :resume_on => :sleep }
    order.pass_to :before, :resume_on => :exit
  end

  it 'resumes the next thread once all its synchronize blocks have completed' do
    order.declare(:thread) { mutex.synchronize { } }
    mutex.synchronize { order.pass_to :thread, :resume_on => :sleep }
    order.apocalypse! :join
  end

  it 'is implemented without depending on the stdlib' do
    loaded_filenames = $LOADED_FEATURES.map { |filepath| File.basename filepath }
    pending 'thread seems to be required from core, and something is still requiring monitor'
    expect(loaded_filenames).to_not include 'monitor.rb'
    expect(loaded_filenames).to_not include 'thread.rb'
    expect(loaded_filenames).to_not include 'thread.bundle'
  end
end
