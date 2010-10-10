source "http://rubygems.org"

gem "rake"
gem "cucumber"
gem "aruba", ">= 0.2.0"
gem "autotest"
gem "rspec-mocks", :path => "."
gem "rspec-core", :path => "../rspec-core"
gem "rspec-expectations", :path => "../rspec-expectations"
gem "relish"

case RUBY_VERSION.to_s
when '1.9.2'
  gem "ruby-debug19"
when /^1.8/
  gem "ruby-debug"
end
