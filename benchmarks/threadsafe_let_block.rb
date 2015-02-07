require 'rspec/core'
require 'rspec/expectations'

# switches between these implementations - https://github.com/rspec/rspec-core/pull/1858/files
# benchmark requested in this PR         - https://github.com/rspec/rspec-core/pull/1858
#
# I ran these by adding "benchmark-ips" to ../Gemfile
# then exported BUNDLE_GEMFILE to point t it
# then ran `bundle exec rspec threadsafe_let_block.rb`

# The old, non-thread safe implementation, imported from the `master`
# branch and pared down.
module NonThreadSafeMemoizedHelpers
  def __memoized
    @__memoized ||= {}
  end

  module ClassMethods
    def let(name, &block)
      # We have to pass the block directly to `define_method` to
      # allow it to use method constructs like `super` and `return`.
      raise "#let or #subject called without a block" if block.nil?
      NonThreadSafeMemoizedHelpers.module_for(self).__send__(:define_method, name, &block)

      # Apply the memoization. The method has been defined in an ancestor
      # module so we can use `super` here to get the value.
      if block.arity == 1
        define_method(name) { __memoized.fetch(name) { |k| __memoized[k] = super(RSpec.current_example, &nil) } }
      else
        define_method(name) { __memoized.fetch(name) { |k| __memoized[k] = super(&nil) } }
      end
    end
  end

  def self.module_for(example_group)
    get_constant_or_yield(example_group, :LetDefinitions) do
      mod = Module.new do
        include Module.new {
          example_group.const_set(:NamedSubjectPreventSuper, self)
        }
      end

      example_group.const_set(:LetDefinitions, mod)
      mod
    end
  end

  # @private
  def self.define_helpers_on(example_group)
    example_group.__send__(:include, module_for(example_group))
  end

  def self.get_constant_or_yield(example_group, name)
    if example_group.const_defined?(name, (check_ancestors = false))
      example_group.const_get(name, check_ancestors)
    else
      yield
    end
  end
end

class HostBase
  def self.prepare_using(memoized_helpers)
    include memoized_helpers
    extend memoized_helpers::ClassMethods
    memoized_helpers.define_helpers_on(self)
    let(:name) { nil }

    counter_class = Class.new(self) do
      memoized_helpers.define_helpers_on(self)
      counter = 0
      let(:count) { counter += 1 }
    end

    verify_memoization_with(counter_class)

    Class.new(self) do
      memoized_helpers.define_helpers_on(self)
      let(:name) { super() }
    end
  end

  def self.verify_memoization_with(counter_class)
    # Since we're using custom code, ensure it actually memoizes as we expect...
    extend RSpec::Matchers

    instance_1 = counter_class.new
    expect(instance_1.count).to eq(1)
    expect(instance_1.count).to eq(1)

    instance_2 = counter_class.new
    expect(instance_2.count).to eq(2)
    expect(instance_2.count).to eq(2)
  end
end

class ThreadSafeHost < HostBase
  Subclass = prepare_using RSpec::Core::MemoizedHelpers
end

class NonThreadSafeHost < HostBase
  Subclass = prepare_using NonThreadSafeMemoizedHelpers
end

def title(title)
  hr    = "#" * (title.length + 6)
  blank = "#  #{' ' * title.length}  #"
  [hr, blank, "#  #{title}  #", blank, hr]
end

require 'benchmark/ips'

# Given
#   let(:name) { nil }
# how many iterations per second for
#   my branch
#   master
# when called
#   once
#   10x
# Same thing with a call to super

puts title "versions"
puts "RUBY_VERSION             #{RUBY_VERSION}"
puts "ruby -v                  #{`ruby -v`}"
puts "Benchmark::IPS::VERSION  #{Benchmark::IPS::VERSION}"
puts "rspec-core SHA           #{`git log --pretty=format:%H -1`}"
puts

puts title "1 call to let -- each sets the value"
Benchmark.ips do |x|
  x.report("threadsafe") { ThreadSafeHost.new.name }
  x.report("non-threadsafe") { NonThreadSafeHost.new.name }
  x.compare!
end

puts title "10 calls to let -- 9 will find memoized value"
Benchmark.ips do |x|
  x.report("threadsafe") do
    i = ThreadSafeHost.new
    i.name; i.name; i.name; i.name; i.name
    i.name; i.name; i.name; i.name; i.name
  end

  x.report("non-threadsafe") do
    i = NonThreadSafeHost.new
    i.name; i.name; i.name; i.name; i.name
    i.name; i.name; i.name; i.name; i.name
  end

  x.compare!
end

puts title "1 call to let which invokes super"

Benchmark.ips do |x|
  x.report("threadsafe") { ThreadSafeHost::Subclass.new.name }
  x.report("non-threadsafe") { NonThreadSafeHost::Subclass.new.name }
  x.compare!
end

puts title "10 calls to let which invokes super"
Benchmark.ips do |x|
  x.report("threadsafe") do
    i = ThreadSafeHost::Subclass.new
    i.name; i.name; i.name; i.name; i.name
    i.name; i.name; i.name; i.name; i.name
  end

  x.report("non-threadsafe") do
    i = NonThreadSafeHost::Subclass.new
    i.name; i.name; i.name; i.name; i.name
    i.name; i.name; i.name; i.name; i.name
  end

  x.compare!
end

__END__

##############
#            #
#  versions  #
#            #
##############
RUBY_VERSION             2.1.5
ruby -v                  ruby 2.1.5p273 (2014-11-13 revision 48405) [x86_64-darwin12.0]
Benchmark::IPS::VERSION  2.1.1
rspec-core SHA           d371e8468ab75d312515389275cbd94e67f1e65e

##########################################
#                                        #
#  1 call to let -- each sets the value  #
#                                        #
##########################################
Calculating -------------------------------------
          threadsafe    16.059k i/100ms
      non-threadsafe    35.537k i/100ms
-------------------------------------------------
          threadsafe    220.346k (±17.3%) i/s -      1.076M
      non-threadsafe    634.321k (±16.1%) i/s -      3.092M

Comparison:
      non-threadsafe:   634321.2 i/s
          threadsafe:   220346.2 i/s - 2.88x slower

###################################################
#                                                 #
#  10 calls to let -- 9 will find memoized value  #
#                                                 #
###################################################
Calculating -------------------------------------
          threadsafe     5.263k i/100ms
      non-threadsafe    19.789k i/100ms
-------------------------------------------------
          threadsafe     69.083k (±16.1%) i/s -    336.832k
      non-threadsafe    262.122k (±14.0%) i/s -      1.306M

Comparison:
      non-threadsafe:   262121.9 i/s
          threadsafe:    69082.7 i/s - 3.79x slower

#######################################
#                                     #
#  1 call to let which invokes super  #
#                                     #
#######################################
Calculating -------------------------------------
          threadsafe    12.203k i/100ms
      non-threadsafe    29.478k i/100ms
-------------------------------------------------
          threadsafe    158.228k (±15.2%) i/s -    780.992k
      non-threadsafe    457.084k (±15.5%) i/s -      2.240M

Comparison:
      non-threadsafe:   457084.2 i/s
          threadsafe:   158228.5 i/s - 2.89x slower

#########################################
#                                       #
#  10 calls to let which invokes super  #
#                                       #
#########################################
Calculating -------------------------------------
          threadsafe     5.417k i/100ms
      non-threadsafe    16.023k i/100ms
-------------------------------------------------
          threadsafe     59.832k (±15.2%) i/s -    292.518k
      non-threadsafe    228.003k (±13.6%) i/s -      1.122M

Comparison:
      non-threadsafe:   228002.9 i/s
          threadsafe:    59831.6 i/s - 3.81x slower
