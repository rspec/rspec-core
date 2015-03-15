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
RUBY_VERSION             2.1.1
RUBY_PLATFORM            x86_64-darwin13.0
RUBY_ENGINE              ruby
ruby -v                  ruby 2.1.1p76 (2014-02-24 revision 45161) [x86_64-darwin13.0]
Benchmark::IPS::VERSION  2.1.1
rspec-core SHA           47ab55fb65d540c087c91810dfcb866e65235afc

##########################################
#                                        #
#  1 call to let -- each sets the value  #
#                                        #
##########################################
Calculating -------------------------------------
          threadsafe    25.254k i/100ms
      non-threadsafe    51.157k i/100ms
-------------------------------------------------
          threadsafe    323.969k (±10.6%) i/s -      1.616M
      non-threadsafe    782.539k (±11.4%) i/s -      3.888M

Comparison:
      non-threadsafe:   782539.4 i/s
          threadsafe:   323968.9 i/s - 2.42x slower

###################################################
#                                                 #
#  10 calls to let -- 9 will find memoized value  #
#                                                 #
###################################################
Calculating -------------------------------------
          threadsafe    16.456k i/100ms
      non-threadsafe    24.522k i/100ms
-------------------------------------------------
          threadsafe    183.918k (± 9.4%) i/s -    921.536k
      non-threadsafe    304.863k (± 9.1%) i/s -      1.520M

Comparison:
      non-threadsafe:   304862.7 i/s
          threadsafe:   183918.2 i/s - 1.66x slower

#######################################
#                                     #
#  1 call to let which invokes super  #
#                                     #
#######################################
Calculating -------------------------------------
          threadsafe    19.731k i/100ms
      non-threadsafe    39.129k i/100ms
-------------------------------------------------
          threadsafe    239.469k (± 8.2%) i/s -      1.204M
      non-threadsafe    555.343k (±10.1%) i/s -      2.778M

Comparison:
      non-threadsafe:   555342.7 i/s
          threadsafe:   239468.6 i/s - 2.32x slower

#########################################
#                                       #
#  10 calls to let which invokes super  #
#                                       #
#########################################
Calculating -------------------------------------
          threadsafe    13.305k i/100ms
      non-threadsafe    21.778k i/100ms
-------------------------------------------------
          threadsafe    149.574k (± 8.7%) i/s -    745.080k
      non-threadsafe    263.700k (± 9.9%) i/s -      1.307M

Comparison:
      non-threadsafe:   263700.1 i/s
          threadsafe:   149573.5 i/s - 1.76x slower
