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

gem 'rake'

if ENV['DIFF_LCS_VERSION']
  gem 'diff-lcs', ENV['DIFF_LCS_VERSION']
else
  gem 'diff-lcs', '~> 1.4', '>= 1.4.3'
end

gem 'yard', '~> 0.9.24', :require => false

### deps for rdoc.info
group :documentation do
  gem 'redcarpet', :platform => :mri
  gem 'github-markup', :platform => :mri
end

gem 'simplecov', '~> 0.8'

# No need to run rubocop on earlier versions
if RUBY_VERSION >= '2.4' && RUBY_ENGINE == 'ruby'
  gem "rubocop", "~> 0.52.1"
end

# Contracts gem denies that it uses Ruby 2.0 syntax
gem 'contracts', '< 0.16' if RUBY_VERSION < '1.9.0'

# json 2.2.0 denies that it needs Ruby 2.0
gem 'json', '< 2.0.0' if RUBY_VERSION < '2.0.0' || RUBY_ENGINE == 'java'

# Test::Unit was removed from stdlib in Ruby 2.2
gem 'test-unit', '~> 3.0' if RUBY_VERSION.to_f >= 2.2

# Minitest version 5.12.0 relies on Ruby 2.4, but denies it
gem 'minitest', '!= 5.12.0'

eval File.read('Gemfile-custom') if File.exist?('Gemfile-custom')
