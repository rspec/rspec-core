Feature: fuubar

[fuubar](https://github.com/thekompanee/fuubar) is an instafailing formatter
that uses a progress bar instead of a string of letters and dots as feedback.

It provides visual feedback of how many specs are left to be run as well as
a rough approximation of how long it will take.

![demo](https://kompanee-public-assets.s3.amazonaws.com/readmes/fuubar-examples.gif)

Installation
--------------------------------------------------------------------------------

```ruby
gem install fuubar

# or in your Gemfile

gem 'fuubar'
```

Usage
--------------------------------------------------------------------------------

In order to use fuubar, you have three options.

### Option 1: Invoke It Manually Via The Command Line

```bash
rspec --format Fuubar --color
```

### Option 2: Add It To Your Local `.rspec` File

```text
# .rspec

--format Fuubar
--color
```

### Option 3: Add It To Your `spec_helper.rb`

```ruby
# spec/spec_helper.rb

RSpec.configure do |config|
  config.add_formatter 'Fuubar'
end
```

---

For more information, you can [view the fuubar
README](https://github.com/thekompanee/fuubar)
