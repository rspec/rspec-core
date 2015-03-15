require 'rspec/core'
require 'rspec/expectations'

# switches between these implementations - https://github.com/rspec/rspec-core/pull/1858/files
# benchmark requested in this PR         - https://github.com/rspec/rspec-core/pull/1858
#
# I ran these from lib root by adding "gem 'benchmark-ips'" to ../Gemfile-custom
# then ran `bundle exec ruby benchmarks/threadsafe_let_block.rb`

# The old, non-thread safe implementation, imported from the `master` branch and pared down.
module OriginalNonThreadSafeMemoizedHelpers
  def __memoized
    @__memoized ||= {}
  end

  module ClassMethods
    def let(name, &block)
      # We have to pass the block directly to `define_method` to
      # allow it to use method constructs like `super` and `return`.
      raise "#let or #subject called without a block" if block.nil?
      OriginalNonThreadSafeMemoizedHelpers.module_for(self).__send__(:define_method, name, &block)

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
  # wires the implementation
  # adds `let(:name) { nil }`
  # returns `Class.new(self) { let(:name) { super() } }`
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

ConfigNonThreadSafeMemoizedHelpers = ::RSpec::Core::MemoizedHelpers.dup
ConfigNonThreadSafeMemoizedHelpers.module_eval do
  def __memoized
    @__memoized ||= NonThreadSafeMemoized.new
  end

  class NonThreadSafeMemoized
    def initialize
      @memoized = {}
    end

    def fetch_or_store(key)
      @memoized.fetch(key) { @memoized[key] = yield }
    end
  end
end

class ThreadSafeHost < HostBase
  Subclass = prepare_using RSpec::Core::MemoizedHelpers
end

class OriginalNonThreadSafeHost < HostBase
  Subclass = prepare_using OriginalNonThreadSafeMemoizedHelpers
end

class ConfigNonThreadSafeHost < HostBase
  Subclass = prepare_using ConfigNonThreadSafeMemoizedHelpers
end

def title(title)
  hr    = "#" * (title.length + 6)
  blank = "#  #{' ' * title.length}  #"
  [hr, blank, "#  #{title}  #", blank, hr]
end

require 'benchmark/ips'

puts title "versions"
puts "RUBY_VERSION             #{RUBY_VERSION}"
puts "RUBY_PLATFORM            #{RUBY_PLATFORM}"
puts "RUBY_ENGINE              #{RUBY_ENGINE}"
puts "ruby -v                  #{`ruby -v`}"
puts "Benchmark::IPS::VERSION  #{Benchmark::IPS::VERSION}"
puts "rspec-core SHA           #{`git log --pretty=format:%H -1`}"
puts

puts title "1 call to let -- each sets the value"
Benchmark.ips do |x|
  x.report("non-threadsafe (original)") { OriginalNonThreadSafeHost.new.name }
  x.report("non-threadsafe (config)  ") { ConfigNonThreadSafeHost.new.name }
  x.report("threadsafe               ") { ThreadSafeHost.new.name }
  x.compare!
end

puts title "10 calls to let -- 9 will find memoized value"
Benchmark.ips do |x|
  x.report("non-threadsafe (original)") do
    i = OriginalNonThreadSafeHost.new
    i.name; i.name; i.name; i.name; i.name
    i.name; i.name; i.name; i.name; i.name
  end

  x.report("non-threadsafe (config)  ") do
    i = ConfigNonThreadSafeHost.new
    i.name; i.name; i.name; i.name; i.name
    i.name; i.name; i.name; i.name; i.name
  end

  x.report("threadsafe               ") do
    i = ThreadSafeHost.new
    i.name; i.name; i.name; i.name; i.name
    i.name; i.name; i.name; i.name; i.name
  end

  x.compare!
end

puts title "1 call to let which invokes super"

Benchmark.ips do |x|
  x.report("non-threadsafe (original)") { OriginalNonThreadSafeHost::Subclass.new.name }
  x.report("non-threadsafe (config)  ") { ConfigNonThreadSafeHost::Subclass.new.name }
  x.report("threadsafe               ") { ThreadSafeHost::Subclass.new.name }
  x.compare!
end

puts title "10 calls to let which invokes super"
Benchmark.ips do |x|
  x.report("non-threadsafe (original)") do
    i = OriginalNonThreadSafeHost::Subclass.new
    i.name; i.name; i.name; i.name; i.name
    i.name; i.name; i.name; i.name; i.name
  end

  x.report("non-threadsafe (config)  ") do
    i = ConfigNonThreadSafeHost::Subclass.new
    i.name; i.name; i.name; i.name; i.name
    i.name; i.name; i.name; i.name; i.name
  end

  x.report("threadsafe               ") do
    i = ThreadSafeHost::Subclass.new
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
RUBY_PLATFORM            x86_64-darwin12.0
RUBY_ENGINE              ruby
ruby -v                  ruby 2.1.5p273 (2014-11-13 revision 48405) [x86_64-darwin12.0]
Benchmark::IPS::VERSION  2.1.1
rspec-core SHA           e32ada9cd4423cdf06df9ef6a99f8ad7b6e13bec

##########################################
#                                        #
#  1 call to let -- each sets the value  #
#                                        #
##########################################
Calculating -------------------------------------
non-threadsafe (original)
                        28.248k i/100ms
non-threadsafe (config)
                        23.804k i/100ms
threadsafe
                        13.001k i/100ms
-------------------------------------------------
non-threadsafe (original)
                        478.456k (±13.1%) i/s -      2.373M
non-threadsafe (config)
                        465.080k (±17.6%) i/s -      2.261M
threadsafe
                        240.298k (± 9.2%) i/s -      1.196M

Comparison:
non-threadsafe (original):   478456.0 i/s
non-threadsafe (config)  :   465080.3 i/s - 1.03x slower
threadsafe               :   240298.3 i/s - 1.99x slower

###################################################
#                                                 #
#  10 calls to let -- 9 will find memoized value  #
#                                                 #
###################################################
Calculating -------------------------------------
non-threadsafe (original)
                        20.678k i/100ms
non-threadsafe (config)
                        17.564k i/100ms
threadsafe
                        12.120k i/100ms
-------------------------------------------------
non-threadsafe (original)
                        272.546k (± 8.0%) i/s -      1.365M
non-threadsafe (config)
                        226.533k (± 7.1%) i/s -      1.142M
threadsafe
                        146.561k (± 7.2%) i/s -    739.320k

Comparison:
non-threadsafe (original):   272545.7 i/s
non-threadsafe (config)  :   226532.8 i/s - 1.20x slower
threadsafe               :   146561.4 i/s - 1.86x slower

#######################################
#                                     #
#  1 call to let which invokes super  #
#                                     #
#######################################
Calculating -------------------------------------
non-threadsafe (original)
                        30.780k i/100ms
non-threadsafe (config)
                        26.364k i/100ms
threadsafe
                        14.261k i/100ms
-------------------------------------------------
non-threadsafe (original)
                        478.578k (± 9.0%) i/s -      2.401M
non-threadsafe (config)
                        395.975k (± 7.7%) i/s -      1.977M
threadsafe
                        176.326k (± 6.5%) i/s -    884.182k

Comparison:
non-threadsafe (original):   478578.3 i/s
non-threadsafe (config)  :   395975.1 i/s - 1.21x slower
threadsafe               :   176326.3 i/s - 2.71x slower

#########################################
#                                       #
#  10 calls to let which invokes super  #
#                                       #
#########################################
Calculating -------------------------------------
non-threadsafe (original)
                        18.380k i/100ms
non-threadsafe (config)
                        16.342k i/100ms
threadsafe
                        10.262k i/100ms
-------------------------------------------------
non-threadsafe (original)
                        235.513k (± 6.9%) i/s -      1.176M
non-threadsafe (config)
                        200.389k (± 5.4%) i/s -      1.013M
threadsafe
                        121.804k (± 7.6%) i/s -    605.458k

Comparison:
non-threadsafe (original):   235512.9 i/s
non-threadsafe (config)  :   200389.0 i/s - 1.18x slower
threadsafe               :   121803.9 i/s - 1.93x slower
