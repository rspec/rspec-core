require 'bundler'
Bundler.setup

require 'rake'
require 'rspec/mocks/version'
require 'rspec/core/rake_task'
require 'cucumber/rake/task'

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

RSpec::Core::RakeTask.new(:spec)

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.rcov = true
  spec.rcov_opts = %[--exclude "core,expectations,gems/*,spec/resources,spec/spec,spec/spec_helper.rb,db/*,/Library/Ruby/*,config/*" --text-summary  --sort coverage]
end

class Cucumber::Rake::Task::ForkedCucumberRunner
  # When cucumber shells out, we still need it to run in the context of our
  # bundle.
  def run
    sh "bundle exec #{RUBY} " + args.join(" ")
  end
end

Cucumber::Rake::Task.new do |t|
  t.cucumber_opts = %w{--format progress}
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
