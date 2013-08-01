require 'benchmark'
require 'delegate'
require 'forwardable'

class Original

  def my_method
    true
  end

end

class Delegated < DelegateClass(Original)
  def initialize
    super(Original.new)
  end
end

class Composed
  def initialize
    @original = Original.new
  end

  define_method(:my_method) { @original.my_method }
end

class Forwarded
  extend Forwardable

  def initialize
    @object = Original.new
  end

  def_delegators :@object, :my_method
end

n = 100_000

Benchmark.benchmark do |bm|
  puts "#{n} times - ruby #{RUBY_VERSION}"

  puts "[control] straight to obj"
  bm.report do
    n.times do
      Original.new.my_method
    end
  end

  puts "[delegate] DelegateClass to obj"
  bm.report do
    n.times do
      Delegated.new.my_method
    end
  end

  puts "[composed] passed to obj"
  bm.report do
    n.times do
      Composed.new.my_method
    end
  end

  puts "[forwarded] passed to obj"
  bm.report do
    n.times do
      Forwarded.new.my_method
    end
  end

end

# 100000 times - ruby 2.0.0
# [control] straight to obj
# 0.040000   0.000000   0.040000 (  0.038468)
# [delegate] DelegateClass to obj
# 0.230000   0.000000   0.230000 (  0.234356)
# [composed] passed to obj
# 0.070000   0.000000   0.070000 (  0.071021)
