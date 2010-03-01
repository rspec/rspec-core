require 'rubygems'
require 'rake'
require 'cucumber/rake/task'

$:.unshift File.expand_path(File.join(File.dirname(__FILE__),'lib'))

require 'rspec/mocks/version'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "rspec-mocks"
    gem.version = Rspec::Mocks::Version::STRING
    gem.summary = "rspec-mocks-#{Rspec::Mocks::Version::STRING}"
    gem.description = "Rspec's 'test double' framework, with support for stubbing and mocking"
    gem.email = "dchelimsky@gmail.com;chad.humphries@gmail.com"
    gem.homepage = "http://github.com/rspec/mocks"
    gem.authors = ["David Chelimsky", "Chad Humphries"]    
    gem.rubyforge_project = "rspec"
    gem.add_development_dependency('rspec-core', ">= #{Rspec::Mocks::Version::STRING}")
    gem.add_development_dependency('rspec-expectations', ">= #{Rspec::Mocks::Version::STRING}")
    gem.add_development_dependency('mocha')
    gem.add_development_dependency('flexmock')
    gem.add_development_dependency('rr')
    gem.post_install_message = <<-EOM
#{"*"*50}

  Thank you for installing #{gem.summary}

  The 'a' in #{gem.version} means this is alpha software.
  If you are looking for a supported production release,
  please "gem install rspec" (without --pre).
  
#{"*"*50}
EOM
  end
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

begin
  require 'rspec/core/rake_task'
  Rspec::Core::RakeTask.new(:spec)

  Rspec::Core::RakeTask.new(:rcov) do |spec|
    spec.rcov = true
    spec.rcov_opts = %[--exclude "core,expectations,gems/*,spec/resources,spec/spec,spec/spec_helper.rb,db/*,/Library/Ruby/*,config/*" --text-summary  --sort coverage]
  end
rescue LoadError
  puts "Rspec core or one of its dependencies is not installed. Install it with: gem install rspec-meta"
end

Cucumber::Rake::Task.new

task :clobber do
  rm_rf 'pkg'
  rm_rf 'tmp'
  rm_rf 'coverage'
end

task :default => [:check_dependencies, :spec, :cucumber]

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "rspec-mocks #{Rspec::Mocks::Version::STRING}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

