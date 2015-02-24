require 'rspec/core'
require 'rspec/expectations'

# switches between these implementations - https://github.com/rspec/rspec-core/pull/1858/files
# benchmark requested in this PR         - https://github.com/rspec/rspec-core/pull/1858
#
# I ran these from lib root by adding "gem 'benchmark-ips'" to ../Gemfile-custom
# then ran `bundle exec ruby benchmarks/threadsafe_let_block.rb`

# The old, non-thread safe implementation, imported from the `master` branch and pared down.
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
RUBY_VERSION             2.2.0
RUBY_PLATFORM            x86_64-darwin13
RUBY_ENGINE              ruby
ruby -v                  ruby 2.2.0p0 (2014-12-25 revision 49005) [x86_64-darwin13]
Benchmark::IPS::VERSION  2.1.1
rspec-core SHA           1dc69cd816fed7dd9f638e13ca2b1831d5c0174e

##########################################
#                                        #
#  1 call to let -- each sets the value  #
#                                        #
##########################################
Calculating -------------------------------------
          threadsafe    25.316k i/100ms
      non-threadsafe    47.650k i/100ms
-------------------------------------------------
          threadsafe    330.940k (±15.5%) i/s -      1.620M
      non-threadsafe    745.917k (±15.6%) i/s -      3.621M

Comparison:
      non-threadsafe:   745917.1 i/s
          threadsafe:   330939.6 i/s - 2.25x slower

###################################################
#                                                 #
#  10 calls to let -- 9 will find memoized value  #
#                                                 #
###################################################
Calculating -------------------------------------
          threadsafe     9.671k i/100ms
      non-threadsafe    23.823k i/100ms
-------------------------------------------------
          threadsafe    100.772k (±15.0%) i/s -    493.221k
      non-threadsafe    314.779k (±14.2%) i/s -      1.548M

Comparison:
      non-threadsafe:   314779.4 i/s
          threadsafe:   100772.2 i/s - 3.12x slower

#######################################
#                                     #
#  1 call to let which invokes super  #
#                                     #
#######################################
Calculating -------------------------------------
          threadsafe    20.027k i/100ms
      non-threadsafe    40.314k i/100ms
-------------------------------------------------
          threadsafe    258.225k (±15.7%) i/s -      1.262M
      non-threadsafe    528.911k (±14.9%) i/s -      2.580M

Comparison:
      non-threadsafe:   528911.3 i/s
          threadsafe:   258224.5 i/s - 2.05x slower

#########################################
#                                       #
#  10 calls to let which invokes super  #
#                                       #
#########################################
Calculating -------------------------------------
          threadsafe     9.022k i/100ms
      non-threadsafe    21.712k i/100ms
-------------------------------------------------
          threadsafe     89.125k (±13.9%) i/s -    442.078k
      non-threadsafe    266.991k (±15.7%) i/s -      1.303M

Comparison:
      non-threadsafe:   266991.2 i/s
          threadsafe:    89124.8 i/s - 3.00x slower

=============================================================================================

##############
#            #
#  versions  #
#            #
##############
RUBY_VERSION             2.1.0
RUBY_PLATFORM            x86_64-darwin14.1.0
RUBY_ENGINE              rbx
ruby -v                  rubinius 2.5.0 (2.1.0 50777f41 2015-01-17 3.5.0 JI) [x86_64-darwin14.1.0]
Benchmark::IPS::VERSION  2.1.1
rspec-core SHA           1dc69cd816fed7dd9f638e13ca2b1831d5c0174e

##########################################
#                                        #
#  1 call to let -- each sets the value  #
#                                        #
##########################################
Calculating -------------------------------------
          threadsafe    12.566k i/100ms
      non-threadsafe    84.582k i/100ms
-------------------------------------------------
          threadsafe    715.795k (±17.2%) i/s -      3.431M
      non-threadsafe      1.187M (±14.6%) i/s -      5.836M

Comparison:
      non-threadsafe:  1186820.2 i/s
          threadsafe:   715794.8 i/s - 1.66x slower

###################################################
#                                                 #
#  10 calls to let -- 9 will find memoized value  #
#                                                 #
###################################################
Calculating -------------------------------------
          threadsafe    12.456k i/100ms
      non-threadsafe    27.749k i/100ms
-------------------------------------------------
          threadsafe    137.480k (±14.0%) i/s -    672.624k
      non-threadsafe    320.032k (±13.5%) i/s -      1.582M

Comparison:
      non-threadsafe:   320031.6 i/s
          threadsafe:   137479.6 i/s - 2.33x slower

#######################################
#                                     #
#  1 call to let which invokes super  #
#                                     #
#######################################
Calculating -------------------------------------
          threadsafe    37.193k i/100ms
      non-threadsafe    60.695k i/100ms
-------------------------------------------------
          threadsafe    466.347k (±12.9%) i/s -      2.306M
      non-threadsafe    763.771k (±16.1%) i/s -      3.702M

Comparison:
      non-threadsafe:   763771.5 i/s
          threadsafe:   466347.0 i/s - 1.64x slower

#########################################
#                                       #
#  10 calls to let which invokes super  #
#                                       #
#########################################
Calculating -------------------------------------
          threadsafe    11.484k i/100ms
      non-threadsafe    25.345k i/100ms
-------------------------------------------------
          threadsafe    129.065k (±14.0%) i/s -    631.620k
      non-threadsafe    279.116k (±14.4%) i/s -      1.369M

Comparison:
      non-threadsafe:   279115.8 i/s
          threadsafe:   129064.7 i/s - 2.16x slower
