source "https://rubygems.org"

gemspec

branch = File.read(File.expand_path("../maintenance-branch", __FILE__)).chomp
%w[rspec rspec-expectations rspec-mocks rspec-support].each do |lib|
  library_path = File.expand_path("../../#{lib}", __FILE__)
  if File.exist?(library_path) && !ENV['USE_GIT_REPOS']
    gem lib, :path => library_path
  else
    gem lib, :git => "https://github.com/rspec/#{lib}.git", :branch => branch
  end
end

gem 'yard', '~> 0.9.24', :require => false

### deps for rdoc.info
group :documentation do
  gem 'redcarpet', :platform => :mri
  gem 'github-markup', :platform => :mri
  gem 'yard', '~> 0.9.24', :require => false
end

if RUBY_VERSION < '2.0.0'
  gem 'thor', '< 1.0.0'
else
  gem 'thor', '> 1.0.0'
end

if RUBY_VERSION < '2.4.0' && !!(RbConfig::CONFIG['host_os'] =~ /cygwin|mswin|mingw|bccwin|wince|emx/)
  gem 'ffi', '< 1.15'
else
  gem 'ffi', '~> 1.15.0'
end

gem "jruby-openssl", platforms: :jruby

group :coverage do
  gem 'simplecov', '~> 0.8'
end

# No need to run rubocop on earlier versions
if RUBY_VERSION >= '2.4' && RUBY_ENGINE == 'ruby'
  gem "rubocop", "~> 1.0", "< 1.12"
end

gem 'test-unit', '~> 3.0'

# Version 5.12 of minitest requires Ruby 2.4
if RUBY_VERSION < '2.4.0'
  gem 'minitest', '< 5.12.0'
end

eval File.read('Gemfile-custom') if File.exist?('Gemfile-custom')
