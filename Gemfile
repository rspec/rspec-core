source "https://rubygems.org"

gemspec

branch = File.read(File.expand_path("../maintenance-branch", __FILE__)).chomp
%w[rspec rspec-expectations rspec-mocks rspec-support].each do |lib|
  library_path = File.expand_path("../../#{lib}", __FILE__)
  if File.exist?(library_path) && !ENV['USE_GIT_REPOS']
    gem lib, :path => library_path
  else
    gem lib, :git => "git://github.com/rspec/#{lib}.git", :branch => branch
  end
end

gem 'yard', '~> 0.8.7', :require => false

### deps for rdoc.info
group :documentation do
  gem 'redcarpet',     '2.1.1', :platform => :mri
  gem 'github-markup', '0.7.2', :platform => :mri
end

platforms :ruby_18, :jruby do
  gem 'json'
end

platforms :jruby do
  gem "jruby-openssl"
end

gem 'simplecov', '~> 0.8'
gem 'rubocop', "~> 0.23.0", :platform => [:ruby_19, :ruby_20, :ruby_21]
gem 'test-unit', '~> 3.0' if RUBY_VERSION.to_f >= 2.2
gem 'aruba', :github => 'cucumber/aruba'

eval File.read('Gemfile-custom') if File.exist?('Gemfile-custom')
