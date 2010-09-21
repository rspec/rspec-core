#!/usr/bin/env ruby

require 'rake'
require 'rake/tasklib'

module RSpec
  module Core

    class RakeTask < ::Rake::TaskLib

      # Name of task.
      #
      # default:
      #   :spec
      attr_accessor :name

      # Glob pattern to match files.
      #
      # default:
      #   'spec/**/*_spec.rb'
      attr_accessor :pattern

      # Deprecated. Use ruby_opts="-w" instead.
      # When true, requests that the specs be run with the warning flag set.
      # e.g. "ruby -w"
      #
      # default:
      #   false
      attr_reader :warning

      def warning=(true_or_false)
        RSpec.deprecate("warning", 'ruby_opts="-w"')
        @warning = true_or_false
      end

      # Whether or not to fail Rake when an error occurs (typically when examples fail).
      #
      # default:
      #   true
      attr_accessor :fail_on_error

      # A message to print to stderr when there are failures.
      attr_accessor :failure_message

      # Use verbose output. If this is set to true, the task will print the
      # executed spec command to stdout.
      #
      # default:
      #   false
      attr_accessor :verbose

      # Use rcov for code coverage?
      #
      # default:
      #   false
      attr_accessor :rcov

      # Path to rcov.
      #
      # defaults:
      #   'rcov'
      attr_accessor :rcov_path

      # Command line options to pass to rcov.
      #
      # default:
      #   nil
      attr_accessor :rcov_opts

      # Command line options to pass to ruby.
      #
      # default:
      #   nil
      attr_accessor :ruby_opts

      # Command line options to pass to rspec.
      #
      # default:
      #   nil
      attr_accessor :rspec_opts

      # Deprecated. Use rspec_opts instead.
      def spec_opts=(opts)
        RSpec.deprecate("spec_opts","rspec_opts")
        @rspec_opts = opts
      end

      def initialize(*args)
        @name = args.shift || :spec
        @pattern, @rcov_path, @rcov_opts, @ruby_opts, @rspec_opts = nil, nil, nil, nil, nil
        @warning, @rcov = false, false
        @fail_on_error = true

        yield self if block_given?

        @rcov_path ||= 'rcov'
        @pattern ||= './spec/**/*_spec.rb'

        desc("Run RSpec code examples") unless ::Rake.application.last_comment

        task name do
          RakeFileUtils.send(:verbose, verbose) do
            if files_to_run.empty?
              puts "No examples matching #{pattern} could be found"
            else
              puts spec_command.inspect if verbose
              unless ruby(spec_command)
                STDERR.puts failure_message if failure_message
                raise("#{spec_command} failed") if fail_on_error
              end
            end
          end
        end
      end

      def files_to_run # :nodoc:
        FileList[ pattern ].map { |f| %["#{f}"] }
      end

    private

      def spec_command
        @spec_command ||= begin
                            cmd_parts = [ruby_opts]
                            cmd_parts << "-w" if warning?
                            cmd_parts << "-S"
                            cmd_parts << "bundle exec" if bundler?
                            cmd_parts << runner
                            cmd_parts << runner_options 
                            cmd_parts << files_to_run
                            cmd_parts.flatten.compact.reject(&blank).join(" ")
                          end
      end

    private

      def runner
        rcov ? rcov_path : 'rspec'
      end

      def runner_options
        rcov ? [rcov_opts] : [rspec_opts]
      end

      def bundler?
        File.exist?("./Gemfile")
      end

      def warning?
        warning
      end

      def blank
        lambda {|s| s == ""}
      end

    end

  end
end
