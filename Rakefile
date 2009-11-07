require 'rubygems'
require 'rake'

$:.unshift File.expand_path(File.join(File.dirname(__FILE__),'lib'))

require 'rspec/mocks/version'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "rspec-mocks"
    gem.summary = "rspec-mocks"
    gem.email = "dchelimsky@gmail.com;chad.humphries@gmail.com"
    gem.homepage = "http://github.com/rspec/mocks"
    gem.authors = ["David Chelimsky", "Chad Humphries"]    
    gem.version = Rspec::Mocks::Version::STRING
    gem.add_development_dependency('rspec-core', ">= #{Rspec::Mocks::Version::STRING}")
    gem.add_development_dependency('rspec-expectations', ">= #{Rspec::Mocks::Version::STRING}")
    gem.add_development_dependency('mocha')
    gem.add_development_dependency('flexmock')
    gem.add_development_dependency('rr')
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rspec/core/rake_task'
Rspec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
end

Rspec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
  spec.rcov_opts = %[--exclude "core,expectations,gems/*,spec/resources,spec/spec,spec/spec_helper.rb,db/*,/Library/Ruby/*,config/*" --text-summary  --sort coverage]
end

task :clobber do
  rm_rf 'pkg'
end

task :default => [:check_dependencies, :spec]

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION.yml')
    config = YAML.load(File.read('VERSION.yml'))
    version = "#{config[:major]}.#{config[:minor]}.#{config[:patch]}"
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "rspec-mocks #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

