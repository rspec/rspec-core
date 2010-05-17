$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require 'rake'
require 'rspec/mocks/version'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "rspec-mocks"
    gem.version = RSpec::Mocks::Version::STRING
    gem.summary = "rspec-mocks-#{RSpec::Mocks::Version::STRING}"
    gem.description = "RSpec's 'test double' framework, with support for stubbing and mocking"
    gem.email = "dchelimsky@gmail.com;chad.humphries@gmail.com"
    gem.homepage = "http://github.com/rspec/mocks"
    gem.authors = ["David Chelimsky", "Chad Humphries"]    
    gem.rubyforge_project = "rspec"
    gem.add_development_dependency 'rspec-core', RSpec::Mocks::Version::STRING
    gem.add_development_dependency 'rspec-expectations', RSpec::Mocks::Version::STRING
    gem.post_install_message = <<-EOM
#{"*"*50}

  Thank you for installing #{gem.summary}

  This is beta software. If you are looking
  for a supported production release, please
  "gem install rspec" (without --pre).
  
#{"*"*50}
EOM
  end
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

namespace :gem do
  desc "push to gemcutter"
  task :push => :build do
    system "gem push pkg/rspec-mocks-#{RSpec::Mocks::Version::STRING}.gem"
  end
end

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)

  RSpec::Core::RakeTask.new(:rcov) do |spec|
    spec.rcov = true
    spec.rcov_opts = %[--exclude "core,expectations,gems/*,spec/resources,spec/spec,spec/spec_helper.rb,db/*,/Library/Ruby/*,config/*" --text-summary  --sort coverage]
  end
rescue LoadError
  puts "RSpec core or one of its dependencies is not installed. Install it with: gem install rspec-meta"
end

begin
  require 'cucumber/rake/task'
  Cucumber::Rake::Task.new do |t|
    t.cucumber_opts = %w{--format progress}
  end
rescue LoadError
  puts "Cucumber or one of its dependencies is not installed. Install it with: gem install cucumber"
end

task :clobber do
  rm_rf 'pkg'
  rm_rf 'tmp'
  rm_rf 'coverage'
end

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "rspec-mocks #{RSpec::Mocks::Version::STRING}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

task :default => [:check_dependencies, :spec, :cucumber]
