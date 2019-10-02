source "https://rubygems.org"

gemspec

branch = File.read(File.expand_path("../maintenance-branch", __FILE__)).chomp
<<<<<<< HEAD
%w[rspec rspec-expectations rspec-mocks rspec-support].each do |lib|
=======
%w[rspec rspec-core rspec-mocks rspec-support].each do |lib|
>>>>>>> rspec-expectations/master
  library_path = File.expand_path("../../#{lib}", __FILE__)
  if File.exist?(library_path) && !ENV['USE_GIT_REPOS']
    gem lib, :path => library_path
  else
    gem lib, :git => "https://github.com/rspec/#{lib}.git", :branch => branch
  end
end

<<<<<<< HEAD
if RUBY_VERSION >= '2.0.0'
  gem 'rake', '>= 10.0.0'
elsif RUBY_VERSION >= '1.9.3'
  gem 'rake', '< 12.0.0' # rake 12 requires Ruby 2.0.0 or later
else
  gem 'rake', '< 11.0.0' # rake 11 requires Ruby 1.9.3 or later
end

=======
gem 'coderay' # for syntax highlighting
>>>>>>> rspec-expectations/master
gem 'yard', '~> 0.9.12', :require => false

### deps for rdoc.info
group :documentation do
<<<<<<< HEAD
  gem 'redcarpet',     '2.1.1', :platform => :mri
  gem 'github-markup', '0.7.2', :platform => :mri
end

if RUBY_VERSION < '2.0.0' || RUBY_ENGINE == 'java'
  gem 'json', '< 2.0.0'
end

if RUBY_VERSION < '2.2.0' && !!(RbConfig::CONFIG['host_os'] =~ /cygwin|mswin|mingw|bccwin|wince|emx/)
  gem 'ffi', '< 1.10'
elsif RUBY_VERSION < '2.0'
  gem 'ffi', '< 1.9.19' # ffi dropped Ruby 1.8 support in 1.9.19
else
  gem 'ffi', '~> 1.11.0'
=======
  gem 'redcarpet',     '2.1.1',   :platform => :mri
  gem 'github-markup', '0.7.2'
end

gem 'simplecov'

if RUBY_VERSION < '2.0.0' || RUBY_ENGINE == 'java'
  gem 'json', '< 2.0.0' # is a dependency of simplecov
end

# allow gems to be installed on older rubies and/or windows
if RUBY_VERSION < '2.2.0' && !!(RbConfig::CONFIG['host_os'] =~ /cygwin|mswin|mingw|bccwin|wince|emx/)
  gem 'ffi', '< 1.10'
elsif RUBY_VERSION < '1.9'
  gem 'ffi', '< 1.9.19' # ffi dropped Ruby 1.8 support in 1.9.19
elsif RUBY_VERSION < '2.0'
  gem 'ffi', '< 1.11.0' # ffi dropped Ruby 1.9 support in 1.11.0
else
  gem 'ffi', '> 1.9.24' # prevent Github security vulnerability warning
>>>>>>> rspec-expectations/master
end

if RUBY_VERSION < '2.2.0' && !!(RbConfig::CONFIG['host_os'] =~ /cygwin|mswin|mingw|bccwin|wince|emx/)
  gem "childprocess", "< 1.0.0"
end

<<<<<<< HEAD
=======
if RUBY_VERSION < '1.9.2'
  gem 'contracts', '~> 0.15.0' # is a dependency of aruba
end

# Version 5.12 of minitest requires Ruby 2.4
if RUBY_VERSION < '2.4.0'
  gem 'minitest', '< 5.12.0'
end

>>>>>>> rspec-expectations/master
platforms :jruby do
  if RUBY_VERSION < '1.9.0'
    # Pin jruby-openssl on older J Ruby
    gem "jruby-openssl", "< 0.10.0"
<<<<<<< HEAD
    # Pin child-process on older J Ruby
=======
    # Pin childprocess on older J Ruby
>>>>>>> rspec-expectations/master
    gem "childprocess", "< 1.0.0"
  else
    gem "jruby-openssl"
  end
end

<<<<<<< HEAD
gem 'simplecov', '~> 0.8'

# No need to run rubocop on earlier versions
if RUBY_VERSION >= '2.4' && RUBY_ENGINE == 'ruby'
  gem "rubocop", "~> 0.52.1"
end

gem 'test-unit', '~> 3.0' if RUBY_VERSION.to_f >= 2.2

# Version 5.12 of minitest requires Ruby 2.4
if RUBY_VERSION < '2.4.0'
  gem 'minitest', '< 5.12.0'
end


gem 'contracts', '< 0.16' if RUBY_VERSION < '1.9.0'

=======
platforms :rbx do
  gem 'rubysl'
end

if RUBY_VERSION >= '2.4' && RUBY_ENGINE == 'ruby'
  gem 'rubocop', "~> 0.52.1"
end

>>>>>>> rspec-expectations/master
eval File.read('Gemfile-custom') if File.exist?('Gemfile-custom')
