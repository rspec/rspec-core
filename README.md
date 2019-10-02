<<<<<<< HEAD
# rspec-core [![Build Status](https://secure.travis-ci.org/rspec/rspec-core.svg?branch=master)](http://travis-ci.org/rspec/rspec-core) [![Code Climate](https://codeclimate.com/github/rspec/rspec-core.svg)](https://codeclimate.com/github/rspec/rspec-core)

rspec-core provides the structure for writing executable examples of how your
code should behave, and an `rspec` command with tools to constrain which
examples get run and tailor the output.

## Install

    gem install rspec      # for rspec-core, rspec-expectations, rspec-mocks
    gem install rspec-core # for rspec-core only
    rspec --help
=======
# RSpec Expectations [![Build Status](https://secure.travis-ci.org/rspec/rspec-expectations.svg?branch=master)](http://travis-ci.org/rspec/rspec-expectations) [![Code Climate](https://codeclimate.com/github/rspec/rspec-expectations.svg)](https://codeclimate.com/github/rspec/rspec-expectations)

RSpec::Expectations lets you express expected outcomes on an object in an
example.

```ruby
expect(account.balance).to eq(Money.new(37.42, :USD))
```

## Install

If you want to use rspec-expectations with rspec, just install the rspec gem
and RubyGems will also install rspec-expectations for you (along with
rspec-core and rspec-mocks):

    gem install rspec
>>>>>>> rspec-expectations/master

Want to run against the `master` branch? You'll need to include the dependent
RSpec repos as well. Add the following to your `Gemfile`:

```ruby
<<<<<<< HEAD
%w[rspec rspec-core rspec-expectations rspec-mocks rspec-support].each do |lib|
=======
%w[rspec-core rspec-expectations rspec-mocks rspec-support].each do |lib|
>>>>>>> rspec-expectations/master
  gem lib, :git => "https://github.com/rspec/#{lib}.git", :branch => 'master'
end
```

<<<<<<< HEAD
## Basic Structure

RSpec uses the words "describe" and "it" so we can express concepts like a conversation:

    "Describe an order."
    "It sums the prices of its line items."

```ruby
RSpec.describe Order do
  it "sums the prices of its line items" do
    order = Order.new

=======
If you want to use rspec-expectations with another tool, like Test::Unit,
Minitest, or Cucumber, you can install it directly:

    gem install rspec-expectations

## Contributing

Once you've set up the environment, you'll need to cd into the working
directory of whichever repo you want to work in. From there you can run the
specs and cucumber features, and make patches.

NOTE: You do not need to use rspec-dev to work on a specific RSpec repo. You
can treat each RSpec repo as an independent project.

- [Build details](BUILD_DETAIL.md)
- [Code of Conduct](CODE_OF_CONDUCT.md)
- [Detailed contributing guide](CONTRIBUTING.md)
- [Development setup guide](DEVELOPMENT.md)

## Basic usage

Here's an example using rspec-core:

```ruby
RSpec.describe Order do
  it "sums the prices of the items in its line items" do
    order = Order.new
>>>>>>> rspec-expectations/master
    order.add_entry(LineItem.new(:item => Item.new(
      :price => Money.new(1.11, :USD)
    )))
    order.add_entry(LineItem.new(:item => Item.new(
      :price => Money.new(2.22, :USD),
      :quantity => 2
    )))
<<<<<<< HEAD

=======
>>>>>>> rspec-expectations/master
    expect(order.total).to eq(Money.new(5.55, :USD))
  end
end
```

<<<<<<< HEAD
The `describe` method creates an [ExampleGroup](http://rubydoc.info/gems/rspec-core/RSpec/Core/ExampleGroup).  Within the
block passed to `describe` you can declare examples using the `it` method.

Under the hood, an example group is a class in which the block passed to
`describe` is evaluated. The blocks passed to `it` are evaluated in the
context of an _instance_ of that class.

## Nested Groups

You can also declare nested groups using the `describe` or `context`
methods:

```ruby
RSpec.describe Order do
  context "with no items" do
    it "behaves one way" do
      # ...
    end
  end

  context "with one item" do
    it "behaves another way" do
      # ...
    end
  end
end
```

Nested groups are subclasses of the outer example group class, providing
the inheritance semantics you'd want for free.

## Aliases

You can declare example groups using either `describe` or `context`.
For a top level example group, `describe` and `context` are available
off of `RSpec`. For backwards compatibility, they are also available
off of the `main` object and `Module` unless you disable monkey
patching.

You can declare examples within a group using any of `it`, `specify`, or
`example`.

## Shared Examples and Contexts

Declare a shared example group using `shared_examples`, and then include it
in any group using `include_examples`.

```ruby
RSpec.shared_examples "collections" do |collection_class|
  it "is empty when first created" do
    expect(collection_class.new).to be_empty
  end
end

RSpec.describe Array do
  include_examples "collections", Array
end

RSpec.describe Hash do
  include_examples "collections", Hash
end
```

Nearly anything that can be declared within an example group can be declared
within a shared example group. This includes `before`, `after`, and `around`
hooks, `let` declarations, and nested groups/contexts.

You can also use the names `shared_context` and `include_context`. These are
pretty much the same as `shared_examples` and `include_examples`, providing
more accurate naming when you share hooks, `let` declarations, helper methods,
etc, but no examples.

## Metadata

rspec-core stores a metadata hash with every example and group, which
contains their descriptions, the locations at which they were
declared, etc, etc. This hash powers many of rspec-core's features,
including output formatters (which access descriptions and locations),
and filtering before and after hooks.

Although you probably won't ever need this unless you are writing an
extension, you can access it from an example like this:

```ruby
it "does something" do |example|
  expect(example.metadata[:description]).to eq("does something")
end
```

### `described_class`

When a class is passed to `describe`, you can access it from an example
using the `described_class` method, which is a wrapper for
`example.metadata[:described_class]`.

```ruby
RSpec.describe Widget do
  example do
    expect(described_class).to equal(Widget)
  end
end
```

This is useful in extensions or shared example groups in which the specific
class is unknown. Taking the collections shared example group from above, we can
clean it up a bit using `described_class`:

```ruby
RSpec.shared_examples "collections" do
  it "is empty when first created" do
    expect(described_class.new).to be_empty
  end
end

RSpec.describe Array do
  include_examples "collections"
end

RSpec.describe Hash do
  include_examples "collections"
end
```

## A Word on Scope

RSpec has two scopes:

* **Example Group**: Example groups are defined by a `describe` or
  `context` block, which is eagerly evaluated when the spec file is
  loaded. The block is evaluated in the context of a subclass of
  `RSpec::Core::ExampleGroup`, or a subclass of the parent example group
  when you're nesting them.
* **Example**: Examples -- typically defined by an `it` block -- and any other
  blocks with per-example semantics -- such as a `before(:example)` hook -- are
  evaluated in the context of
  an _instance_ of the example group class to which the example belongs.
  Examples are _not_ executed when the spec file is loaded; instead,
  RSpec waits to run any examples until all spec files have been loaded,
  at which point it can apply filtering, randomization, etc.

To make this more concrete, consider this code snippet:

``` ruby
RSpec.describe "Using an array as a stack" do
  def build_stack
    []
  end

  before(:example) do
    @stack = build_stack
  end

  it 'is initially empty' do
    expect(@stack).to be_empty
  end

  context "after an item has been pushed" do
    before(:example) do
      @stack.push :item
    end

    it 'allows the pushed item to be popped' do
      expect(@stack.pop).to eq(:item)
    end
  end
end
```

Under the covers, this is (roughly) equivalent to:

``` ruby
class UsingAnArrayAsAStack < RSpec::Core::ExampleGroup
  def build_stack
    []
  end

  def before_example_1
    @stack = build_stack
  end

  def it_is_initially_empty
    expect(@stack).to be_empty
  end

  class AfterAnItemHasBeenPushed < self
    def before_example_2
      @stack.push :item
    end

    def it_allows_the_pushed_item_to_be_popped
      expect(@stack.pop).to eq(:item)
    end
  end
end
```

To run these examples, RSpec would (roughly) do the following:

``` ruby
example_1 = UsingAnArrayAsAStack.new
example_1.before_example_1
example_1.it_is_initially_empty

example_2 = UsingAnArrayAsAStack::AfterAnItemHasBeenPushed.new
example_2.before_example_1
example_2.before_example_2
example_2.it_allows_the_pushed_item_to_be_popped
```

## The `rspec` Command

When you install the rspec-core gem, it installs the `rspec` executable,
which you'll use to run rspec. The `rspec` command comes with many useful
options.
Run `rspec --help` to see the complete list.

## Store Command Line Options `.rspec`

You can store command line options in a `.rspec` file in the project's root
directory, and the `rspec` command will read them as though you typed them on
the command line.

## Get Started

Start with a simple example of behavior you expect from your system. Do
this before you write any implementation code:

```ruby
# in spec/calculator_spec.rb
RSpec.describe Calculator do
  describe '#add' do
    it 'returns the sum of its arguments' do
      expect(Calculator.new.add(1, 2)).to eq(3)
    end
  end
end
```

Run this with the rspec command, and watch it fail:

```
$ rspec spec/calculator_spec.rb
./spec/calculator_spec.rb:1: uninitialized constant Calculator
```

Address the failure by defining a skeleton of the `Calculator` class:

```ruby
# in lib/calculator.rb
class Calculator
  def add(a, b)
  end
end
```

Be sure to require the implementation file in the spec:

```ruby
# in spec/calculator_spec.rb
# - RSpec adds ./lib to the $LOAD_PATH
require "calculator"
```

Now run the spec again, and watch the expectation fail:

```
$ rspec spec/calculator_spec.rb
F

Failures:

  1) Calculator#add returns the sum of its arguments
     Failure/Error: expect(Calculator.new.add(1, 2)).to eq(3)

       expected: 3
            got: nil

       (compared using ==)
     # ./spec/calcalator_spec.rb:6:in `block (3 levels) in <top (required)>'

Finished in 0.00131 seconds (files took 0.10968 seconds to load)
1 example, 1 failure

Failed examples:

rspec ./spec/calcalator_spec.rb:5 # Calculator#add returns the sum of its arguments
```

Implement the simplest solution, by changing the definition of `Calculator#add` to:

```ruby
def add(a, b)
  a + b
end
```

Now run the spec again, and watch it pass:

```
$ rspec spec/calculator_spec.rb
.

Finished in 0.000315 seconds
1 example, 0 failures
```

Use the `documentation` formatter to see the resulting spec:

```
$ rspec spec/calculator_spec.rb --format doc
Calculator
  #add
    returns the sum of its arguments

Finished in 0.000379 seconds
1 example, 0 failures
```

## Contributing

Once you've set up the environment, you'll need to cd into the working
directory of whichever repo you want to work in. From there you can run the
specs and cucumber features, and make patches.

NOTE: You do not need to use rspec-dev to work on a specific RSpec repo. You
can treat each RSpec repo as an independent project.

* [Build details](BUILD_DETAIL.md)
* [Code of Conduct](CODE_OF_CONDUCT.md)
* [Detailed contributing guide](CONTRIBUTING.md)
* [Development setup guide](DEVELOPMENT.md)

## Also see

* [https://github.com/rspec/rspec](https://github.com/rspec/rspec)
* [https://github.com/rspec/rspec-expectations](https://github.com/rspec/rspec-expectations)
=======
The `describe` and `it` methods come from rspec-core.  The `Order`, `LineItem`, `Item` and `Money` classes would be from _your_ code. The last line of the example
expresses an expected outcome. If `order.total == Money.new(5.55, :USD)`, then
the example passes. If not, it fails with a message like:

    expected: #<Money @value=5.55 @currency=:USD>
         got: #<Money @value=1.11 @currency=:USD>

## Built-in matchers

### Equivalence

```ruby
expect(actual).to eq(expected)  # passes if actual == expected
expect(actual).to eql(expected) # passes if actual.eql?(expected)
expect(actual).not_to eql(not_expected) # passes if not(actual.eql?(expected))
```

Note: The new `expect` syntax no longer supports the `==` matcher.

### Identity

```ruby
expect(actual).to be(expected)    # passes if actual.equal?(expected)
expect(actual).to equal(expected) # passes if actual.equal?(expected)
```

### Comparisons

```ruby
expect(actual).to be >  expected
expect(actual).to be >= expected
expect(actual).to be <= expected
expect(actual).to be <  expected
expect(actual).to be_within(delta).of(expected)
```

### Regular expressions

```ruby
expect(actual).to match(/expression/)
```

Note: The new `expect` syntax no longer supports the `=~` matcher.

### Types/classes

```ruby
expect(actual).to be_an_instance_of(expected) # passes if actual.class == expected
expect(actual).to be_a(expected)              # passes if actual.kind_of?(expected)
expect(actual).to be_an(expected)             # an alias for be_a
expect(actual).to be_a_kind_of(expected)      # another alias
```

### Truthiness

```ruby
expect(actual).to be_truthy   # passes if actual is truthy (not nil or false)
expect(actual).to be true     # passes if actual == true
expect(actual).to be_falsy    # passes if actual is falsy (nil or false)
expect(actual).to be false    # passes if actual == false
expect(actual).to be_nil      # passes if actual is nil
expect(actual).to_not be_nil  # passes if actual is not nil
```

### Expecting errors

```ruby
expect { ... }.to raise_error
expect { ... }.to raise_error(ErrorClass)
expect { ... }.to raise_error("message")
expect { ... }.to raise_error(ErrorClass, "message")
```

### Expecting throws

```ruby
expect { ... }.to throw_symbol
expect { ... }.to throw_symbol(:symbol)
expect { ... }.to throw_symbol(:symbol, 'value')
```

### Yielding

```ruby
expect { |b| 5.tap(&b) }.to yield_control # passes regardless of yielded args

expect { |b| yield_if_true(true, &b) }.to yield_with_no_args # passes only if no args are yielded

expect { |b| 5.tap(&b) }.to yield_with_args(5)
expect { |b| 5.tap(&b) }.to yield_with_args(Integer)
expect { |b| "a string".tap(&b) }.to yield_with_args(/str/)

expect { |b| [1, 2, 3].each(&b) }.to yield_successive_args(1, 2, 3)
expect { |b| { :a => 1, :b => 2 }.each(&b) }.to yield_successive_args([:a, 1], [:b, 2])
```

### Predicate matchers

```ruby
expect(actual).to be_xxx         # passes if actual.xxx?
expect(actual).to have_xxx(:arg) # passes if actual.has_xxx?(:arg)
```

### Ranges (Ruby >= 1.9 only)

```ruby
expect(1..10).to cover(3)
```

### Collection membership

```ruby
# exact order, entire collection
expect(actual).to eq(expected)

# exact order, partial collection (based on an exact position)
expect(actual).to start_with(expected)
expect(actual).to end_with(expected)

# any order, entire collection
expect(actual).to match_array(expected)

# You can also express this by passing the expected elements
# as individual arguments
expect(actual).to contain_exactly(expected_element1, expected_element2)

 # any order, partial collection
expect(actual).to include(expected)
```

#### Examples

```ruby
expect([1, 2, 3]).to eq([1, 2, 3])            # Order dependent equality check
expect([1, 2, 3]).to include(1)               # Exact ordering, partial collection matches
expect([1, 2, 3]).to include(2, 3)            #
expect([1, 2, 3]).to start_with(1)            # As above, but from the start of the collection
expect([1, 2, 3]).to start_with(1, 2)         #
expect([1, 2, 3]).to end_with(3)              # As above but from the end of the collection
expect([1, 2, 3]).to end_with(2, 3)           #
expect({:a => 'b'}).to include(:a => 'b')     # Matching within hashes
expect("this string").to include("is str")    # Matching within strings
expect("this string").to start_with("this")   #
expect("this string").to end_with("ring")     #
expect([1, 2, 3]).to contain_exactly(2, 3, 1) # Order independent matches
expect([1, 2, 3]).to match_array([3, 2, 1])   #

# Order dependent compound matchers
expect(
  [{:a => 'hash'},{:a => 'another'}]
).to match([a_hash_including(:a => 'hash'), a_hash_including(:a => 'another')])
```

## `should` syntax

In addition to the `expect` syntax, rspec-expectations continues to support the
`should` syntax:

```ruby
actual.should eq expected
actual.should be > 3
[1, 2, 3].should_not include 4
```

See [detailed information on the `should` syntax and its usage.](https://github.com/rspec/rspec-expectations/blob/master/Should.md)

## Compound Matcher Expressions

You can also create compound matcher expressions using `and` or `or`:

``` ruby
expect(alphabet).to start_with("a").and end_with("z")
expect(stoplight.color).to eq("red").or eq("green").or eq("yellow")
```

## Composing Matchers

Many of the built-in matchers are designed to take matchers as
arguments, to allow you to flexibly specify only the essential
aspects of an object or data structure. In addition, all of the
built-in matchers have one or more aliases that provide better
phrasing for when they are used as arguments to another matcher.

### Examples

```ruby
expect { k += 1.05 }.to change { k }.by( a_value_within(0.1).of(1.0) )

expect { s = "barn" }.to change { s }
  .from( a_string_matching(/foo/) )
  .to( a_string_matching(/bar/) )

expect(["barn", 2.45]).to contain_exactly(
  a_value_within(0.1).of(2.5),
  a_string_starting_with("bar")
)

expect(["barn", "food", 2.45]).to end_with(
  a_string_matching("foo"),
  a_value > 2
)

expect(["barn", 2.45]).to include( a_string_starting_with("bar") )

expect(:a => "food", :b => "good").to include(:a => a_string_matching(/foo/))

hash = {
  :a => {
    :b => ["foo", 5],
    :c => { :d => 2.05 }
  }
}

expect(hash).to match(
  :a => {
    :b => a_collection_containing_exactly(
      a_string_starting_with("f"),
      an_instance_of(Integer)
    ),
    :c => { :d => (a_value < 3) }
  }
)

expect { |probe|
  [1, 2, 3].each(&probe)
}.to yield_successive_args( a_value < 2, 2, a_value > 2 )
```

## Usage outside rspec-core

You always need to load `rspec/expectations` even if you only want to use one part of the library:

```ruby
require 'rspec/expectations'
```

Then simply include `RSpec::Matchers` in any class:

```ruby
class MyClass
  include RSpec::Matchers

  def do_something(arg)
    expect(arg).to be > 0
    # do other stuff
  end
end
```

## Also see

* [https://github.com/rspec/rspec](https://github.com/rspec/rspec)
* [https://github.com/rspec/rspec-core](https://github.com/rspec/rspec-core)
>>>>>>> rspec-expectations/master
* [https://github.com/rspec/rspec-mocks](https://github.com/rspec/rspec-mocks)
* [https://github.com/rspec/rspec-rails](https://github.com/rspec/rspec-rails)
