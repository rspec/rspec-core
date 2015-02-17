class ThreadOrderSupport
  def initialize
    @bodies     = {}
    @threads    = []
    @queue      = [] # we may not have thread stdlib required, so may not have Queue class
    @mutex      = Mutex.new
    @worker     = Thread.new { loop { work } }
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
    resume_event = extract_resume_event! options
    body         = @bodies.fetch name
    event        = lambda do |event|
      return unless event == sync { resume_event }
      sync { resume_event = :has_passed }
      parent.wakeup
    end

    child = Thread.new do
      begin
        event.call :run
        Thread.current[:thread_order_name] = name
        body.call
      rescue Exception => error
        parent.raise error
        raise
      ensure
        event.call :exit
      end
    end

    sync { @threads << child }

    sync { resume_event == :sleep } &&
      watch_for_sleep(child) { event.call :sleep }

    sync { resume_event == :has_passed } ||
      sleep

    child
  end

  def apocalypse!
    enqueue do
      sync { @threads.each(&:kill) }
      @queue.clear
      @worker.kill
    end
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
    return if thread.status == false
    thread.status == 'sleep' && cb.call
    enqueue { watch_for_sleep(thread, &cb) }
  end
end
