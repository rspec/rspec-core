<!---
This file was generated on 2016-09-28T20:00:38+10:00 from the rspec-dev repo.
DO NOT modify it by hand as your changes will get lost the next time it is generated.
-->

# Contributing

RSpec is a community-driven project that has benefited from improvements from over *500* contributors.
We welcome contributions from *everyone*. While contributing, please follow the project [code of conduct](CODE_OF_CONDUCT.md), so that everyone can be included.

If you'd like to help make RSpec better, here are some ways you can contribute:

  - by running RSpec HEAD to help us catch bugs before new releases
  - by [reporting bugs you encounter](https://github.com/rspec/rspec-core/issues/new) with [report template](#report-template)
  - by [suggesting new features](https://github.com/rspec/rspec-core/issues/new)
  - by improving RSpec's [Relish](https://relishapp.com/rspec) or [API](http://rspec.info/documentation/) documentation
  - by improving [RSpec's website](http://rspec.info/) ([source](https://github.com/rspec/rspec.github.io))
  - by taking part in [feature and issue discussions](https://github.com/rspec/rspec-core/issues)
  - by adding a failing test for reproducible [reported bugs](https://github.com/rspec/rspec-core/issues)
  - by reviewing [pull requests](https://github.com/rspec/rspec-core/pulls) and suggesting improvements
  - by [writing code](DEVELOPMENT.md) (no patch is too small! fix typos or bad whitespace)

If you need help getting started, check out the [DEVELOPMENT](DEVELOPMENT.md) file for steps that will get you up and running.

Thanks for helping us make RSpec better!

## `Small` issues

These issue are ones that we be believe are best suited for new contributors to
get started with. They represent a meaningful contribution to the project that
should not be too hard to pull off.

## Report template

Having a way to reproduce your issue will be very helpful for others to help confirm, investigate and ultimately fix your issue. You can do this by providing an executable test case. To make this process easier, we have prepared one basic bug report templates for you to use as a starting point:

```ruby
# frozen_string_literal: true

begin
  require "bundler/inline"
rescue LoadError => e
  $stderr.puts "Bundler version 1.10 or later is required. Please update your Bundler"
  raise e
end

gemfile(true) do
  source "https://rubygems.org"

  gem 'aruba' # Needed to execute RSpec from Ruby code
  gem "rspec", "3.7.0" # Activate the gem and version you are reporting the issue against.
end

puts "Ruby version is: #{RUBY_VERSION}"

describe 'additions' do
  it 'returns 2' do
    expect(1 + 1).to eq(2)
  end

  it 'returns 1' do
    expect(3 - 1).to eq(-1)
  end
end

RSpec::Core::Runner.invoke
```

Simply copy the content of the appropriate template into a `.rb` file on your computer and make the necessary changes to demonstrate the issue. You can execute it by running `ruby the_file.rb` in your terminal.

You can then share your executable test case as a [gist](https://gist.github.com), or simply paste the content into the issue description.

## Maintenance branches

Maintenance branches are how we manage the different supported point releases
of RSpec. As such, while they might look like good candidates to merge into
master, please do not open pull requests to merge them.
