# rspec-mocks-2.2

## What's new

### `require "rspec/mocks/standalone"`

Sets up top-level environment to explore rspec-mocks. Mostly useful in irb:

    $ irb
    > require 'rspec/mocks/standalone'
    > foo = double()
    > foo.stub(:bar) { :baz }
    > foo.bar
      => :baz
