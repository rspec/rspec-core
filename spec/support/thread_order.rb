class ThreadOrderSupport
  def initialize
    @bodies  = {}
    @threads = []
    @queue   = [] # we may not have thread stdlib required, so may not have Queue class
    @mutex   = Mutex.new
    @worker  = Thread.new { loop { work } }
    @worker.abort_on_exception = true
  end

  def declare(name, &block)
    @bodies[name] = block
  end

  def current
    Thread.current[:thread_order_name]
  end

  def pass_to(name, options)
    parent       = Thread.current
    child        = nil
    resume_event = extract_resume_event! options
    resume_if    = lambda do |event|
      return unless event == sync { resume_event }
      parent.wakeup
    end

    enqueue do
      child = Thread.new do
        enqueue { @threads << child }
        sync { resume_event } == :sleep &&
          enqueue { watch_for_sleep(child) { resume_if.call :sleep } }
        begin
          enqueue { resume_if.call :run }
          Thread.current[:thread_order_name] = name
          @bodies.fetch(name).call
        rescue Exception => error
          enqueue { parent.raise error }
          raise
        ensure
          enqueue { resume_if.call :exit }
        end
      end
    end

    sleep
    child
  end

  def apocalypse!(thread_method=:kill)
    enqueue do
      @threads.each(&thread_method)
      @queue.clear
      @worker.kill
    end
    @worker.join
  end

  private

  def sync(&block)
    @mutex.synchronize(&block)
  end

  def enqueue(&block)
    sync { @queue << block }
  end

  def work
    task = sync { @queue.shift }
    task ||= lambda { Thread.pass }
    task.call
  end

  def extract_resume_event!(options)
    resume_on = options.delete :resume_on
    options.any? &&
      raise(ArgumentError, "Unknown options: #{options.inspect}")
    resume_on && ![:run, :exit, :sleep].include?(resume_on) and
      raise(ArgumentError, "Unknown status: #{resume_on.inspect}")
    resume_on
  end

  def watch_for_sleep(thread, &cb)
    if thread.status == false || thread.status == nil
      # noop, dead threads dream no dreams
    elsif thread.status == 'sleep'
      cb.call
    else
      enqueue { watch_for_sleep(thread, &cb) }
    end
  end
end
