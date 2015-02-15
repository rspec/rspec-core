class ThreadOrderSupport
  def initialize(errstream)
    @mutex     = Mutex.new
    @errstream = errstream
    @current   = 1
  end

  def call(turn_number)
    loop do
      @mutex.lock
      break if @current == turn_number
      @mutex.unlock
      Thread.pass
    end
    yield
  rescue Exception => e
    @errstream << "#{e.inspect}\n#{e.backtrace}"
    raise
  ensure
    @current += 1
    @mutex.unlock
  end
end
