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
end

# Until 1.13.2 is released due to Rubygems usage
gem 'ffi', '~> 1.12.0'

gem "jruby-openssl", platforms: :jruby

gem 'simplecov', '~> 0.8'

# No need to run rubocop on earlier versions
if RUBY_VERSION >= '2.4' && RUBY_ENGINE == 'ruby'
  gem "rubocop", "~> 0.52.1"
end

gem 'test-unit', '~> 3.0'

# Version 5.12 of minitest requires Ruby 2.4
if RUBY_VERSION < '2.4.0'
  gem 'minitest', '< 5.12.0'
end

eval File.read('Gemfile-custom') if File.exist?('Gemfile-custom')
