RSpec.describe ThreadOrderSupport do
  let!(:order)  { described_class.new $stderr }

  it 'begins turns at 1' do
    ran = false
    order.call(1) { ran = true }
    expect(ran).to eq true
  end

  it 'runs each codeblock when it is that code\'s turn' do
    seen    = []
    threads = 10.downto(1).map do |i|
      Thread.new { order.call(i) { seen << i } }
    end
    threads.each(&:join)
    expect(seen).to eq (1..10).to_a
  end

  it 'returns whatever the block returned' do
    expect(order.call(1) { :block_returned }).to eq :block_returned
  end

  describe 'exceptions' do
    def call(&block)
      stream    = ""
      exception = nil
      begin
        described_class.new(stream).call(1, &block)
      rescue Exception => e
        exception = e
      end
      {:stream => stream, :exception => exception}
    end

    def stream_for(&block)
      call(&block).fetch :stream
    end

    def error_for(&block)
      call(&block).fetch :exception
    end

    it 'prints the class to the error stream' do
      expect(stream_for { raise ZeroDivisionError }).to include 'ZeroDivisionError'
    end

    it 'prints the message to the error stream' do
      expect(stream_for { raise 'the message' }).to include 'the message'
    end

    it 'prints the backtrace to the error stream' do
      expect(stream_for { raise }).to include "#{__FILE__}:#{__LINE__}"
    end

    it 'reraises the exception with the original backtrace' do
      error = error_for do
        raise # place on its own line to avoid false positive from the method invocation
      end
      expect(error.backtrace).to be_any { |line| line.include?  "#{__FILE__}:#{__LINE__ - 2}" }
    end

    it 'does this for all exception types, even Exception' do
      error = error_for { raise Exception }
      expect(error.class).to eq Exception
    end

    it 'considers this a valid turn and moves onto the next one' do
      order = described_class.new ""
      begin
        order.call(1) { raise ZeroDivisionError }
      rescue ZeroDivisionError
      end
      order.call(2) { } # shouldn't block/deadlock
    end
  end
end
