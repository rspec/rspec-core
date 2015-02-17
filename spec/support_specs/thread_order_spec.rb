RSpec.describe ThreadOrderSupport do
  let(:order) { described_class.new }
  after { order.apocalypse! }

  it 'allows thread behaviour to be declared and run by name' do
    seen = []
    order.declare(:third)  { seen << :third }
    order.declare(:first)  { seen << :first;  order.pass_to :second, :resume_on => :exit }
    order.declare(:second) { seen << :second; order.pass_to :third,  :resume_on => :exit }
    expect(seen).to eq []
    order.pass_to :first, :resume_on => :exit
    expect(seen).to eq [:first, :second, :third]
  end

  it 'sleeps the thread which passed' do
    main_thread = Thread.current
    order.declare(:thread) { :noop until main_thread.status == 'sleep' }
    order.pass_to :thread, :resume_on => :exit # passes if it doesn't lock up
  end

  context 'resume events' do
    def self.test_status(name, statuses, *args, &threadmaker)
      it "can resume the thread when the called thread enters #{name}", *args do
        thread   = instance_eval(&threadmaker)
        statuses = Array statuses
        expect(statuses).to include thread.status
      end
    end

    test_status ':run', 'run' do
      order.declare(:t) { loop { 1 } }
      order.pass_to :t, :resume_on => :run
    end

    test_status ':sleep', 'sleep' do
      order.declare(:t) { sleep }
      order.pass_to :t, :resume_on => :sleep
    end

    test_status ':exit', [false, 'aborting'] do
      order.declare(:t) { Thread.exit }
      order.pass_to :t, :resume_on => :exit
    end
  end

  describe 'errors in children' do
    specify 'are raised in the child' do
      child = nil
      order.declare(:err) { child = Thread.current; raise 'the roof' }
      (order.pass_to :err, :resume_on => :exit) rescue nil
      child.join                                rescue nil
      expect(child.status).to eq nil
    end

    specify 'are raised in the parent' do
      order.declare(:err) { raise Exception, 'to the rules' }
      expect {
        order.pass_to :err, :resume_on => :run
        loop { :noop }
      }.to raise_error Exception, 'to the rules'
    end

    specify 'even if the parent is asleep' do
      parent = Thread.current
      order.declare(:err) {
        :noop until parent.status == 'sleep'
        raise 'the roof'
      }
      expect {
        order.pass_to :err, :resume_on => :run
        sleep
      }.to raise_error RuntimeError, 'the roof'
    end
  end

  it 'knows which thread is running' do
    thread_names = []
    order.declare(:a) {
      thread_names << order.current
      order.pass_to :b, :resume_on => :exit
      thread_names << order.current
    }
    order.declare(:b) {
      thread_names << order.current
    }
    order.pass_to :a, :resume_on => :exit
    expect(thread_names.sort).to eq [:a, :a, :b]
  end

  it 'returns nil when asked for the current thread by one it did not define' do
    thread_names = []
    order.declare(:a) {
      thread_names << order.current
      Thread.new { thread_names << order.current }.join
    }
    expect(order.current).to eq nil
    order.pass_to :a, :resume_on => :exit
    expect(thread_names).to eq [:a, nil]
  end

  describe 'incorrect interface usage' do
    it 'raises ArgumentError when told to resume on an unknown status' do
      order.declare(:t) { }
      expect { order.pass_to :t, :resume_on => :bad_status }.
        to raise_error(ArgumentError, /bad_status/)
    end

    it 'raises an ArgumentError when you give it unknown keys (ie you spelled resume_on wrong)' do
      order.declare(:t) { }
      expect { order.pass_to :t, :bad_key => :t }.
        to raise_error(ArgumentError, /bad_key/)
    end
  end
end
