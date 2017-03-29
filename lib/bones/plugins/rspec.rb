
module Bones
module Plugins
module Rspec
  include ::Bones::Helpers
  extend self

  def initialize_rspec
    require 'rspec/core/rake_task'
    have?(:rspec) { true }

    ::Bones.config {
      desc 'Configuration settings for the RSpec test framework.'
      rspec {
        files  'spec/**/*_spec.rb', :desc => <<-__
          Glob pattern used to match spec files to run. This defaults to all
          the ruby fines in the 'spec' directory that end with '_spec.rb' as
          their filename.
        __

        opts [], :desc => <<-__
          An array of command line options that will be passed to the rspec
          command when running your tests. See the RSpec help documentation
          either online or from the command line by running 'spec --help'.
        __
      }
    }
  rescue LoadError
    have?(:rspec) { false }
  end

  def post_load
    return unless have? :rspec
    config = ::Bones.config
    have?(:rspec) { !config.rspec.files.to_a.empty?  }
  end

  def define_tasks
    return unless have? :rspec
    config = ::Bones.config

    namespace :rspec do
      desc 'Run all specs with basic output'
      ::RSpec::Core::RakeTask.new(:run) do |t|
        t.ruby_opts = config.ruby_opts
        t.rspec_opts = config.rspec.opts
        t.pattern = config.rspec.files
      end

      desc 'Run all specs with text output'
      ::RSpec::Core::RakeTask.new(:documentation) do |t|
        t.ruby_opts = config.ruby_opts
        t.rspec_opts = config.rspec.opts + ['--format', 'documentation']
        t.pattern = config.rspec.files
      end

      if have? :rcov
        desc 'Run all specs with Rcov'
        ::RSpec::Core::RakeTask.new(:rcov) do |t|
          t.ruby_opts = config.ruby_opts
          t.rspec_opts = config.rspec.opts
          t.pattern = config.rspec.files

          t.rcov = true
          t.rcov_path = config.rcov.path

          rcov_opts = []
          rcov_opts.concat config.rcov.opts
          rcov_opts << '--output' << config.rcov.dir if config.rcov.dir

          t.rcov_opts = rcov_opts
        end

        task :clobber_rcov do
          rm_r config.rcov.dir rescue nil
        end
      end
    end  # namespace :rspec

    desc 'Alias to rspec:run'
    task :rspec => 'rspec:run'

    task :clobber => 'rspec:clobber_rcov' if have? :rcov
  end

end  # module Rspec
end  # module Plugins
end  # module Bones

