require "rbconfig"

module RSpec
  module Core
    class Configuration
      include RSpec::Core::Hooks

      def self.add_setting(name, opts={})
        if opts[:alias]
          alias_method name, opts[:alias]
          alias_method "#{name}=", "#{opts[:alias]}="
          alias_method "#{name}?", "#{opts[:alias]}?"
        else
          define_method("#{name}=") {|val| settings[name] = val}
          define_method(name)       { settings.has_key?(name) ? settings[name] : opts[:default] }
          define_method("#{name}?") { !!(send name) }
        end
      end

      add_setting :error_stream
      add_setting :output_stream
      add_setting :output, :alias => :output_stream
      add_setting :drb
      add_setting :drb_port
      add_setting :color_enabled
      add_setting :profile_examples
      add_setting :run_all_when_everything_filtered
      add_setting :mock_framework, :default => :rspec
      add_setting :filter
      add_setting :exclusion_filter
      add_setting :filename_pattern, :default => '**/*_spec.rb'
      add_setting :files_to_run, :default => []
      add_setting :include_or_extend_modules, :default => []
      add_setting :formatter_class, :default => RSpec::Core::Formatters::ProgressFormatter
      add_setting :backtrace_clean_patterns, :default => [
        /\/lib\/ruby\//,
        /bin\/rcov:/,
        /vendor\/rails/,
        /bin\/rspec/,
        /bin\/spec/,
        /lib\/rspec\/(core|expectations|matchers|mocks)/
      ]

      # :call-seq:
      #   add_setting(:name)
      #   add_setting(:name, :default => "default_value")
      #   add_setting(:name, :alias => :other_setting)
      #
      # Use this to add custom settings to the RSpec.configuration object.
      #
      #   RSpec.configuration.add_setting :foo
      #
      # Creates three methods on the configuration object, a setter, a getter,
      # and a predicate:
      #
      #   RSpec.configuration.foo=(value)
      #   RSpec.configuration.foo()
      #   RSpec.configuration.foo?() # returns !!foo
      #
      # Intended for extension frameworks like rspec-rails, so they can add config
      # settings that are domain specific. For example:
      #
      #   RSpec.configure do |c|
      #     c.add_setting :use_transactional_fixtures, :default => true
      #     c.add_setting :use_transactional_examples, :alias => :use_transactional_fixtures
      #   end
      #
      # == Options
      #
      # +add_setting+ takes an optional hash that supports the following
      # keys:
      #
      #   :default => "default value"
      #
      # This sets the default value for the getter and the predicate (which
      # will return +true+ as long as the value is not +false+ or +nil+).
      #
      #   :alias => :other_setting
      #
      # Aliases its setter, getter, and predicate, to those for the
      # +other_setting+.
      def add_setting(name, opts={})
        self.class.add_setting(name, opts)
      end

      def puts(message)
        output_stream.puts(message)
      end

      def settings
        @settings ||= {}
      end

      def clear_inclusion_filter # :nodoc:
        self.filter = nil
      end

      def cleaned_from_backtrace?(line)
        backtrace_clean_patterns.any? { |regex| line =~ regex }
      end

      def mock_with(mock_framework)
        settings[:mock_framework] = mock_framework
      end

      def require_mock_framework_adapter
        require case mock_framework.to_s
        when /rspec/i
          'rspec/core/mocking/with_rspec'
        when /mocha/i
          'rspec/core/mocking/with_mocha'
        when /rr/i
          'rspec/core/mocking/with_rr'
        when /flexmock/i
          'rspec/core/mocking/with_flexmock'
        else
          'rspec/core/mocking/with_absolutely_nothing'
        end
      end

      def full_backtrace=(bool)
        settings[:backtrace_clean_patterns] = []
      end

      remove_method :color_enabled=

      def color_enabled=(bool)
        return unless bool
        settings[:color_enabled] = true
        if bool && ::RbConfig::CONFIG['host_os'] =~ /mswin|mingw/
          orig_output_stream = settings[:output_stream]
          begin
            require 'Win32/Console/ANSI'
          rescue LoadError
            warn "You must 'gem install win32console' to use colour on Windows"
            settings[:color_enabled] = false
          ensure
            settings[:output_stream] = orig_output_stream
          end
        end
      end

      def libs=(libs)
        libs.map {|lib| $LOAD_PATH.unshift lib}
      end

      def requires=(paths)
        paths.map {|path| require path}
      end

      def debug=(bool)
        return unless bool
        begin
          require 'ruby-debug'
        rescue LoadError
          raise <<-EOM

#{'*'*50}
You must install ruby-debug to run rspec with the --debug option.

If you have ruby-debug installed as a ruby gem, then you need to either
require 'rubygems' or configure the RUBYOPT environment variable with
the value 'rubygems'.
#{'*'*50}
EOM
        end
      end

      def line_number=(line_number)
        filter_run :line_number => line_number.to_i
      end

      def full_description=(description)
        filter_run :full_description => /#{description}/
      end

      def formatter=(formatter_to_use)
        if string_const?(formatter_to_use) && (class_name = eval(formatter_to_use)).is_a?(Class)
          formatter_class = class_name
        elsif formatter_to_use.is_a?(Class)
          formatter_class = formatter_to_use
        else
          formatter_class = case formatter_to_use.to_s
          when 'd', 'doc', 'documentation', 's', 'n', 'spec', 'nested'
            RSpec::Core::Formatters::DocumentationFormatter
          when 'h', 'html'
            RSpec::Core::Formatters::HtmlFormatter
          when 't', 'textmate'
            RSpec::Core::Formatters::TextMateFormatter
          when 'p', 'progress'
            RSpec::Core::Formatters::ProgressFormatter
          else
            raise ArgumentError, "Formatter '#{formatter_to_use}' unknown - maybe you meant 'documentation' or 'progress'?."
          end
        end
        self.formatter_class = formatter_class
      end

      def string_const?(str)
        str.is_a?(String) && /\A[A-Z][a-zA-Z0-9_:]*\z/ =~ str
      end

      def formatter
        @formatter ||= formatter_class.new(output)
      end

      def reporter
        @reporter ||= Reporter.new(formatter)
      end

      def files_or_directories_to_run=(*files)
        self.files_to_run = files.flatten.collect do |file|
          if File.directory?(file)
            filename_pattern.split(",").collect do |pattern|
              Dir["#{file}/#{pattern.strip}"]
            end
          else
            if file =~ /(\:(\d+))$/
              self.line_number = $2
              file.sub($1,'')
            else
              file
            end
          end
        end.flatten
      end

      # E.g. alias_example_to :crazy_slow, :speed => 'crazy_slow' defines
      # crazy_slow as an example variant that has the crazy_slow speed option
      def alias_example_to(new_name, extra_options={})
        RSpec::Core::ExampleGroup.alias_example_to(new_name, extra_options)
      end

      # Define an alias for it_should_behave_like that allows different
      # language (like "it_has_behavior" or "it_behaves_like") to be
      # employed when including shared examples.
      #
      # Example:
      #
      #     alias_it_should_behave_like_to(:it_has_behavior, 'has behavior:')
      #
      # allows the user to include a shared example group like:
      #
      #     describe Entity do
      #       it_has_behavior 'sortability' do
      #         let(:sortable) { Entity.new }
      #       end
      #     end
      #
      # which is reported in the output as:
      #
      #     Entity
      #       has behavior: sortability
      #         # sortability examples here
      def alias_it_should_behave_like_to(new_name, report_label = '')
        RSpec::Core::ExampleGroup.alias_it_should_behave_like_to(new_name, report_label)
      end

      def filter_run_including(options={})
        if filter and filter[:line_number] || filter[:full_description]
          warn "Filtering by #{options.inspect} is not possible since " \
               "you are already filtering by #{filter.inspect}"
        else
          self.filter = options
        end
      end

      alias_method :filter_run, :filter_run_including

      def filter_run_excluding(options={})
        self.exclusion_filter = options
      end

      def include(mod, filters={})
        include_or_extend_modules << [:include, mod, filters]
      end

      def extend(mod, filters={})
        include_or_extend_modules << [:extend, mod, filters]
      end

      def configure_group(group)
        modules = {
          :include => [] + group.included_modules,
          :extend  => [] + group.ancestors
        }

        include_or_extend_modules.each do |include_or_extend, mod, filters|
          next unless group.all_apply?(filters)
          next if modules[include_or_extend].include?(mod)
          modules[include_or_extend] << mod
          group.send(include_or_extend, mod)
        end
      end

      def configure_mock_framework
        require_mock_framework_adapter
        RSpec::Core::ExampleGroup.send(:include, RSpec::Core::MockFrameworkAdapter)
      end

      def load_spec_files
        files_to_run.map {|f| load File.expand_path(f) }
      end
    end
  end
end
