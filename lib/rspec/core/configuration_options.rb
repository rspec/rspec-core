require 'erb'

module RSpec
  module Core
    class ConfigurationOptions
      attr_reader :options

      def initialize(args)
        @args = args
      end

      def configure(config)
        formatters       = options.delete(:formatters)
        inclusion_filter = options.delete(:inclusion_filter)
        exclusion_filter = options.delete(:exclusion_filter)

        order(options.keys, :libs, :requires, :default_path, :pattern).each do |key|
          config.send("#{key}=", options[key]) if config.respond_to?("#{key}=")
        end

        formatters.each {|pair| config.add_formatter(*pair) } if formatters
        config.filter_run_including inclusion_filter          if inclusion_filter
        config.filter_run_excluding exclusion_filter          if exclusion_filter
      end

      def parse_options
        @options ||= [file_options, command_line_options, env_options].inject do |merged, o|
          merged.merge(o) {|key, oldval, newval| [:requires, :libs].include?(key) ? oldval + newval : newval}
        end
      end

      def drb_argv
        DrbOptions.new(options).options
      end

    private

      def order(keys, *ordered)
        ordered.reverse.each do |key|
          keys.unshift(key) if keys.delete(key)
        end
        keys
      end

      def file_options
        custom_options_file ? custom_options : global_options.merge(local_options)
      end

      def env_options
        ENV["SPEC_OPTS"] ? Parser.parse!(ENV["SPEC_OPTS"].split) : {}
      end

      def command_line_options
        @command_line_options ||= Parser.parse!(@args).merge :files_or_directories_to_run => @args
      end

      def custom_options
        options_from(custom_options_file)
      end

      def local_options
        @local_options ||= options_from(local_options_file)
      end

      def global_options
        @global_options ||= options_from(global_options_file)
      end

      def options_from(path)
        Parser.parse(args_from_options_file(path))
      end

      def args_from_options_file(path)
        return [] unless path && File.exist?(path)
        config_string = options_file_as_erb_string(path)
        config_string.split(/\n+/).map {|l| l.split}.flatten
      end

      def options_file_as_erb_string(path)
        ERB.new(File.read(path)).result(binding)
      end

      def custom_options_file
        command_line_options[:custom_options_file]
      end

      def local_options_file
        ".rspec"
      end

      def global_options_file
        begin
          File.join(File.expand_path("~"), ".rspec")
        rescue ArgumentError
          warn "Unable to find ~/.rspec because the HOME environment variable is not set"
          nil
        end
      end
    end
  end
end
