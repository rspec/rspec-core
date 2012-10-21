require "spec_helper"
require "rspec/core/rake_task"
require 'tempfile'

module RSpec::Core
  describe RakeTask do
    let(:task) { RakeTask.new }

    def ruby
      FileUtils::RUBY
    end

    def with_rcov
      task.rcov = true
      yield
    end

    def spec_command
      task.__send__(:spec_command)
    end

    context "with a name passed to the constructor" do
      let(:task) { RakeTask.new(:task_name) }

      it "correctly sets the name" do
        task.name.should == :task_name
      end
    end

    context "with args passed to the rake task" do
      it "correctly passes along task arguments" do
        task = RakeTask.new(:rake_task_args, :files) do |t, args|
          args[:files].should == "first_spec.rb"
        end

        task.should_receive(:run_task) { true }
        Rake.application.invoke_task("rake_task_args[first_spec.rb]").should be_true
      end
    end

    context "default" do
      it "renders rspec" do
        spec_command.should =~ /^#{ruby} -S rspec/
      end
    end

    context "with rcov" do
      it "renders rcov" do
        with_rcov do
          spec_command.should =~ /^#{ruby} -S rcov/
        end
      end
    end

    context "with ruby options" do
      it "renders them before -S" do
          task.ruby_opts = "-w"
          spec_command.should =~ /^#{ruby} -w -S rspec/
      end
    end

    context "with rcov_opts" do
      context "with rcov=false (default)" do
        it "does not add the rcov options to the command" do
          task.rcov_opts = '--exclude "mocks"'
          spec_command.should_not =~ /--exclude "mocks"/
        end
      end

      context "with rcov=true" do
        it "renders them after rcov" do
          task.rcov = true
          task.rcov_opts = '--exclude "mocks"'
          spec_command.should =~ /rcov.*--exclude "mocks"/
        end

        it "ensures that -Ispec:lib is in the resulting command" do
          task.rcov = true
          task.rcov_opts = '--exclude "mocks"'
          spec_command.should =~ /rcov.*-Ispec:lib/
        end
      end
    end

    context "with rspec_opts" do
      context "with rcov=true" do
        it "adds the rspec_opts after the rcov_opts and files" do
          task.stub(:files_to_run) { "this.rb that.rb" }
          task.rcov = true
          task.rspec_opts = "-Ifoo"
          spec_command.should =~ /this.rb that.rb -- -Ifoo/
        end
      end
      context "with rcov=false (default)" do
        it "adds the rspec_opts" do
          task.rspec_opts = "-Ifoo"
          spec_command.should =~ /rspec.*-Ifoo/
        end
      end
    end

    def specify_consistent_ordering_of_files_to_run(pattern, task)
      orderings = [
        %w[ a/1.rb a/2.rb a/3.rb ],
        %w[ a/2.rb a/1.rb a/3.rb ],
        %w[ a/3.rb a/2.rb a/1.rb ]
      ].map do |files|
        FileList.should_receive(:[]).with(pattern) { files }
        task.__send__(:files_to_run)
      end

      orderings.uniq.size.should eq(1)
    end

    context "with SPEC env var set" do
      it "sets files to run" do
        with_env_vars 'SPEC' => 'path/to/file' do
          task.__send__(:files_to_run).should eq(["path/to/file"])
        end
      end

      it "sets the files to run in a consistent order, regardless of the underlying FileList ordering" do
        with_env_vars 'SPEC' => 'a/*.rb' do
          specify_consistent_ordering_of_files_to_run('a/*.rb', task)
        end
      end
    end

    it "sets the files to run in a consistent order, regardless of the underlying FileList ordering" do
      task = RakeTask.new(:consistent_file_order) do |t|
        t.pattern = 'a/*.rb'
      end

      # since the config block is deferred til task invocation, must fake
      # calling the task so the expected pattern is picked up
      task.should_receive(:run_task) { true }
      Rake.application.invoke_task(task.name).should be_true

      specify_consistent_ordering_of_files_to_run('a/*.rb', task)
    end

    context "with paths with quotes" do
      it "escapes the quotes" do
        task.pattern = File.join(Dir.tmpdir, "*spec.rb")
        ["first_spec.rb", "second_\"spec.rb", "third_\'spec.rb"].each do |file_name|
          FileUtils.touch(File.join(Dir.tmpdir, file_name))
        end
        task.__send__(:files_to_run).sort.should eq([
          File.join(Dir.tmpdir, "first_spec.rb"),
          File.join(Dir.tmpdir, "second_\\\"spec.rb"),
          File.join(Dir.tmpdir, "third_\\\'spec.rb")
        ])
      end
    end

    context "with paths including symlinked directories" do
      it "finds the files" do
        project_dir = File.join(Dir.tmpdir, "project")
        FileUtils.rm_rf project_dir

        foos_dir = File.join(project_dir, "spec/foos")
        FileUtils.mkdir_p foos_dir
        FileUtils.touch(File.join(foos_dir, "foo_spec.rb"))

        bars_dir = File.join(Dir.tmpdir, "shared/spec/bars")
        FileUtils.mkdir_p bars_dir
        FileUtils.touch(File.join(bars_dir, "bar_spec.rb"))

        FileUtils.ln_s bars_dir, File.join(project_dir, "spec/bars")

        FileUtils.cd(project_dir) do
          RakeTask.new.__send__(:files_to_run).sort.should eq([
            "./spec/bars/bar_spec.rb",
            "./spec/foos/foo_spec.rb"
          ])
        end
      end
    end
  end
end
