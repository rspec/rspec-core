require "spec_helper"
require "rspec/core/rake_task"
require 'tempfile'

module RSpec::Core
  RSpec.describe RakeTask do
    let(:task) { RakeTask.new }

    def ruby
      FileUtils::RUBY
    end

    def spec_command
      task.__send__(:spec_command)
    end

    context "with a name passed to the constructor" do
      let(:task) { RakeTask.new(:task_name) }

      it "correctly sets the name" do
        expect(task.name).to eq :task_name
      end
    end

    context "with args passed to the rake task" do
      it "correctly passes along task arguments" do
        task = RakeTask.new(:rake_task_args, :files) do |t, args|
          expect(args[:files]).to eq "first_spec.rb"
        end

        expect(task).to receive(:run_task) { true }
        expect(Rake.application.invoke_task("rake_task_args[first_spec.rb]")).to be_truthy
      end
    end

    default_load_path_opts = '-I\S+'

    context "default" do
      it "renders rspec" do
        expect(spec_command).to match(/^#{ruby} #{default_load_path_opts} -S #{task.rspec_path}/)
      end
    end

    context "with ruby options" do
      it "renders them before -S" do
        task.ruby_opts = "-w"
        expect(spec_command).to match(/^#{ruby} -w #{default_load_path_opts} -S #{task.rspec_path}/)
      end
    end

    context "with rspec_opts" do
      it "adds the rspec_opts" do
        task.rspec_opts = "-Ifoo"
        expect(spec_command).to match(/#{task.rspec_path}.*-Ifoo/)
      end
    end

    context "with pattern" do
      it "adds the pattern" do
        task.pattern = "complex_pattern"
        expect(spec_command).to include(" --pattern 'complex_pattern'")
      end
    end

    context 'with custom exit status' do
      it 'returns the correct status on exit', :slow do
        with_isolated_stderr do
          expect($stderr).to receive(:puts) { |cmd| expect(cmd).to match(/-e "exit\(2\);".* failed/) }
          expect(task).to receive(:exit).with(2)
          task.ruby_opts = '-e "exit(2);" ;#'
          task.run_task false
        end
      end
    end

    def specify_consistent_ordering_of_files_to_run(pattern, task)
      orderings = [
        %w[ a/1.rb a/2.rb a/3.rb ],
        %w[ a/2.rb a/1.rb a/3.rb ],
        %w[ a/3.rb a/2.rb a/1.rb ]
      ].map do |files|
        expect(FileList).to receive(:[]).with(pattern) { files }
        task.__send__(:files_to_run)
      end

      expect(orderings.uniq.size).to eq(1)
    end

    context "with SPEC env var set" do
      it "sets files to run" do
        with_env_vars 'SPEC' => 'path/to/file' do
          expect(task.__send__(:files_to_run)).to eq(["path/to/file"])
        end
      end

      it "sets the files to run in a consistent order, regardless of the underlying FileList ordering" do
        with_env_vars 'SPEC' => 'a/*.rb' do
          specify_consistent_ordering_of_files_to_run('a/*.rb', task)
        end
      end
    end

    describe "load path manipulation" do
      around(:example) do |ex|
        # use the `include` matcher to ensure it's already loaded; otherwise,
        # it could be used for the first time below after the load path has
        # been changed, which would trigger an attempted autoload of the `Include`
        # matcher that would fail.
        expect([1]).to include(1)

        orig_load_path = $LOAD_PATH.dup
        ex.run
        $LOAD_PATH.replace(orig_load_path)
      end

      def self.it_configures_rspec_load_path(description, path_template)
        context "when rspec is installed as #{description}" do
          it "adds the current rspec-core and rspec-support dirs to the load path to ensure the current version is used" do
            $LOAD_PATH.replace([
              path_template % "rspec-core",
              path_template % "rspec-support",
              path_template % "rspec-expectations",
              path_template % "rspec-mocks",
              path_template % "rake"
            ])

            expect(spec_command).to include(" -I#{path_template % "rspec-core"}:#{path_template % "rspec-support"} ")
          end
        end
      end

      it_configures_rspec_load_path "bundler :git dependencies",
        "/Users/myron/code/some-gem/bundle/ruby/2.1.0/bundler/gems/%s-8d2e4e570994/lib"

      it_configures_rspec_load_path "bundler :path dependencies",
        "/Users/myron/code/rspec-dev/repos/%s/lib"

      it_configures_rspec_load_path "a rubygem",
        "/Users/myron/.gem/ruby/1.9.3/gems/%s-3.1.0.beta1/lib"

      it "does not include extra load path entries for other gems that have `rspec-core` in its path" do
        # these are items on my load path due to `bundle install --standalone`,
        # and my initial logic caused all these to be included in the `-I` option.
        $LOAD_PATH.replace([
           "/Users/myron/code/rspec-dev/repos/rspec-core/spec",
           "/Users/myron/code/rspec-dev/repos/rspec-core/bundle/ruby/1.9.1/gems/simplecov-0.8.2/lib",
           "/Users/myron/code/rspec-dev/repos/rspec-core/bundle/ruby/1.9.1/gems/simplecov-html-0.8.0/lib",
           "/Users/myron/code/rspec-dev/repos/rspec-core/bundle/ruby/1.9.1/gems/minitest-5.3.3/lib",
           "/Users/myron/code/rspec-dev/repos/rspec/lib",
           "/Users/myron/code/rspec-dev/repos/rspec-mocks/lib",
           "/Users/myron/code/rspec-dev/repos/rspec-core/lib",
           "/Users/myron/code/rspec-dev/repos/rspec-expectations/lib",
           "/Users/myron/code/rspec-dev/repos/rspec-support/lib",
           "/Users/myron/code/rspec-dev/repos/rspec-core/bundle",
        ])

        expect(spec_command).not_to include("simplecov", "minitest", "rspec-core/spec")
      end
    end
  end
end
