require 'bundler'
Bundler.setup
Bundler::GemHelper.install_tasks

require 'rake'
require 'rspec/core/rake_task'
require 'rspec/mocks/version'

desc "Run all examples"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = %w[--color]
end

require 'cucumber/rake/task'
Cucumber::Rake::Task.new(:cucumber)

namespace :rcov do
  desc "Run all examples using rcov"
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.rcov = true
    t.rcov_opts =  %[-Ilib -Ispec --exclude "gems/*,features"]
    t.rcov_opts << %[--text-report --sort coverage --no-html --aggregate coverage.data]
  end

  desc "Run cucumber features using rcov"
  Cucumber::Rake::Task.new(:cucumber) do |t|
    t.cucumber_opts = %w{--format progress}
    t.rcov = true
    t.rcov_opts =  %[-Ilib -Ispec --exclude "gems/*,features"]
    t.rcov_opts << %[--text-report --sort coverage --aggregate coverage.data]
  end

  task :cleanup do
    rm_rf 'coverage.data'
  end
end

desc "run specs and cukes with rcov"
task :rcov => ["rcov:cleanup", "rcov:spec", "rcov:cucumber"]

task :clobber do
  rm_rf 'pkg'
  rm_rf 'tmp'
  rm_rf 'coverage'
end

namespace :clobber do
  desc "remove generated rbc files"
  task :rbc do
    Dir['**/*.rbc'].each {|f| File.delete(f)}
  end
end

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "rspec-mocks #{RSpec::Mocks::Version::STRING}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc "Push docs/cukes to relishapp using the relish-client-gem"
task :relish, :version do |t, args|
  raise "rake relish[VERSION]" unless args[:version]
  sh "relish push rspec/rspec-mocks:#{args[:version]}"
end

task :default => [:rspec, :cucumber]
