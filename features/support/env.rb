require 'aruba/cucumber'

timeouts = { 'java' => 60 }

Before do
  @aruba_timeout_seconds = timeouts.fetch(RUBY_PLATFORM) { 10 }
end

if RUBY_PLATFORM == "java"
  pid = Process.spawn("jruby --ng-server &")
  Aruba.configure do |config|
    config.before_cmd do |cmd|
      set_env('JRUBY_OPTS', "--ng -X-C #{ENV['JRUBY_OPTS']}") # disable JIT since these processes are so short lived
    end
  end

  at_exit do
    Process.spawn("kill #{pid}")
  end
end
