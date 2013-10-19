# A deliberately naive class to count the number of times any particular method
# is called.
class InvocationCounter
  def initialize(method_name)
    @method_name = method_name
    @count       = 0
  end

  def hook!(klass)
    parent = self
    hooker = Module.new do
      define_method(parent.method_name) do |*args|
        parent.count += 1
        super(*args)
      end
    end
    klass.send :include, hooker
  end

  attr_accessor :count
  attr_reader :method_name
end
