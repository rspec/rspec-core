require 'rspec/core'

# switches between these implementations - https://github.com/rspec/rspec-core/pull/1858/files
# benchmark requested in this PR         - https://github.com/rspec/rspec-core/pull/1858
#
# I ran these by adding "benchmark-ips" to ../Gemfile
# then exported BUNDLE_GEMFILE to point t it
# then ran `bundle exec rspec threadsafe_let_block.rb`
class LetBlockImplementationHelper

  MemoizedHelpers = ::RSpec::Core::MemoizedHelpers
  Memoized        = MemoizedHelpers::Memoized

  def title(title)
    hr    = "#" * (title.length + 6)
    blank = "#  #{' ' * title.length}  #"
    [hr, blank, "#  #{title}  #", blank, hr]
  end

  def use_non_threadsafe
    return if @state == :old
    @state = :old
    MemoizedHelpers.module_eval do
      def subject
        __memoized.fetch(:subject) do
          __memoized[:subject] = begin
            described = described_class || self.class.metadata.fetch(:description_args).first
            Class === described ? described.new : described
          end
        end
      end

      def __memoized
        @__memoized ||= {}
      end
    end

    class << MemoizedHelpers::ContextHookMemoized
      alias fetch for
    end

    MemoizedHelpers::ClassMethods.module_eval do
      def let(name, &block)
        # We have to pass the block directly to `define_method` to
        # allow it to use method constructs like `super` and `return`.
        raise "#let or #subject called without a block" if block.nil?
        MemoizedHelpers.module_for(self).__send__(:define_method, name, &block)

        # Apply the memoization. The method has been defined in an ancestor
        # module so we can use `super` here to get the value.
        if block.arity == 1
          define_method(name) { __memoized.fetch(name) { |k| __memoized[k] = super(RSpec.current_example, &nil) } }
        else
          define_method(name) { __memoized.fetch(name) { |k| __memoized[k] = super(&nil) } }
        end
      end
    end
  end


  def use_threadsafe
    return if @state == :new
    @state = :new
    MemoizedHelpers.module_eval do
      def subject
        __memoized.for(:subject) do
          described = described_class || self.class.metadata.fetch(:description_args).first
          Class === described ? described.new : described
        end
      end

      def __memoized
        @__memoized ||= Memoized.new
      end
    end

    MemoizedHelpers::ClassMethods.module_eval do
      def let(name, &block)
        # We have to pass the block directly to `define_method` to
        # allow it to use method constructs like `super` and `return`.
        raise "#let or #subject called without a block" if block.nil?
        MemoizedHelpers.module_for(self).__send__(:define_method, name, &block)

        # Apply the memoization. The method has been defined in an ancestor
        # module so we can use `super` here to get the value.
        if block.arity == 1
          define_method(name) { __memoized.for(name) { super(RSpec.current_example, &nil) } }
        else
          define_method(name) { __memoized.for(name) { super(&nil) } }
        end
      end
    end
  end
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


helper = LetBlockImplementationHelper.new


puts helper.title "versions"
puts "RUBY_VERSION             #{RUBY_VERSION}"
puts "ruby -v                  #{`ruby -v`}"
puts "Benchmark::IPS::VERSION  #{Benchmark::IPS::VERSION}"
puts "rspec-core SHA           #{`git log --pretty=format:%H -1`}"
puts


puts helper.title "1 call to let -- each sets the value"
Benchmark.ips do |x|
  x.report("threadsafe") do |times|
    helper.use_threadsafe
    group = RSpec::Core::ExampleGroup.describe 'threadsafe1' do
      let(:name) { nil }
      times.times { example { name } }
    end
    raise "the run did not succeed!" unless group.run
  end

  x.report("non-threadsafe") do |times|
    helper.use_non_threadsafe
    group = RSpec::Core::ExampleGroup.describe 'non-threadsafe1' do
      let(:name) { nil }
      times.times { example { name } }
    end
    raise "the run did not succeed!" unless group.run
  end

  x.compare!
end


puts helper.title "10 calls to let -- 9 will find memoized value"
Benchmark.ips do |x|
  x.report("threadsafe") do |times|
    helper.use_threadsafe
    group = RSpec::Core::ExampleGroup.describe 'threadsafe2' do
      let(:name) { nil }
      times.times { example { name; name; name; name; name; name; name; name; name; name; } }
    end
    raise "the run did not succeed!" unless group.run
  end

  x.report("non-threadsafe") do |times|
    helper.use_non_threadsafe
    group = RSpec::Core::ExampleGroup.describe 'non-threadsafe2' do
      let(:name) { nil }
      times.times { example { name; name; name; name; name; name; name; name; name; name; } }
    end
    raise "the run did not succeed!" unless group.run
  end

  x.compare!
end


puts helper.title "1 call to let which invokes super"
Benchmark.ips do |x|
  x.report("threadsafe") do |times|
    helper.use_threadsafe
    group = RSpec::Core::ExampleGroup.describe 'threadsafe3' do
      let(:name) { nil }
      describe 'child' do
        let(:name) { super() }
        times.times { example { name } }
      end
    end
    raise "the run did not succeed!" unless group.run
  end

  x.report("non-threadsafe") do |times|
    helper.use_non_threadsafe
    group = RSpec::Core::ExampleGroup.describe 'non-threadsafe3' do
      let(:name) { nil }
      describe 'child' do
        let(:name) { super() }
        times.times { example { name } }
      end
    end
    raise "the run did not succeed!" unless group.run
  end

  x.compare!
end


puts helper.title "10 calls to let which invokes super"
Benchmark.ips do |x|
  x.report("threadsafe") do |times|
    helper.use_threadsafe
    group = RSpec::Core::ExampleGroup.describe 'threadsafe4' do
      let(:name) { nil }
      describe 'child' do
        let(:name) { super() }
        times.times { example { name; name; name; name; name; name; name; name; name; name; } }
      end
    end
    raise "the run did not succeed!" unless group.run
  end

  x.report("non-threadsafe") do |times|
    helper.use_non_threadsafe
    group = RSpec::Core::ExampleGroup.describe 'non-threadsafe4' do
      let(:name) { nil }
      describe 'child' do
        let(:name) { super() }
        times.times { example { name; name; name; name; name; name; name; name; name; name; } }
      end
    end
    raise "the run did not succeed!" unless group.run
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
ruby -v                  ruby 2.2.0p0 (2014-12-25 revision 49005) [x86_64-darwin13]
Benchmark::IPS::VERSION  2.1.1
rspec-core SHA           9daea3316b07736ac536f104d443d2f29e7ed722

##########################################
#                                        #
#  1 call to let -- each sets the value  #
#                                        #
##########################################
Calculating -------------------------------------
          threadsafe   120.000  i/100ms
      non-threadsafe   121.000  i/100ms
-------------------------------------------------
          threadsafe      7.949k (±19.7%) i/s -     35.760k
      non-threadsafe      8.541k (±21.7%) i/s -     35.695k

Comparison:
      non-threadsafe:     8541.2 i/s
          threadsafe:     7948.8 i/s - 1.07x slower

###################################################
#                                                 #
#  10 calls to let -- 9 will find memoized value  #
#                                                 #
###################################################
Calculating -------------------------------------
          threadsafe    45.000  i/100ms
      non-threadsafe    49.000  i/100ms
-------------------------------------------------
          threadsafe      4.894k (±18.7%) i/s -     20.835k
      non-threadsafe      5.603k (±17.8%) i/s -     23.128k

Comparison:
      non-threadsafe:     5603.0 i/s
          threadsafe:     4894.2 i/s - 1.14x slower

#######################################
#                                     #
#  1 call to let which invokes super  #
#                                     #
#######################################
Calculating -------------------------------------
          threadsafe    23.000  i/100ms
      non-threadsafe    25.000  i/100ms
-------------------------------------------------
          threadsafe      2.796k (±15.7%) i/s -     12.029k
      non-threadsafe      3.313k (±13.3%) i/s -     14.200k

Comparison:
      non-threadsafe:     3312.7 i/s
          threadsafe:     2795.8 i/s - 1.18x slower

#########################################
#                                       #
#  10 calls to let which invokes super  #
#                                       #
#########################################
Calculating -------------------------------------
          threadsafe    18.000  i/100ms
      non-threadsafe    18.000  i/100ms
-------------------------------------------------
          threadsafe      2.283k (±12.3%) i/s -      9.684k
      non-threadsafe      2.409k (±12.6%) i/s -     10.890k

Comparison:
      non-threadsafe:     2408.8 i/s
          threadsafe:     2283.1 i/s - 1.06x slower
