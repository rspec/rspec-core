module RSpec::Core
  class Notifier
    def initialize(*subscribers)
      self.subscribers.push(*subscribers)
    end

    def subscribers
      @subscribers ||= []
    end

    def method_missing(method, *args, &block)
      subscribers.each do |s|
        RSpec.publish(method, *args)
        s.send(method, *args, &block) if s.respond_to?(method)
      end
    end
  end
end
