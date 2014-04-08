require "spec_helper"

module RSpec::Core
  RSpec.describe OptionParser do
    before do
      allow(RSpec.configuration).to receive(:reporter) do
        fail "OptionParser is not allowed to access `config.reporter` since we want " +
             "ConfigurationOptions to have the chance to set `deprecation_stream` " +
             "(based on `--deprecation-out`) before the deprecation formatter is " +
             "initialized by the reporter instantiation. If you need to issue a deprecation, " +
             "populate an `options[:deprecations]` key and have ConfigurationOptions " +
             "issue the deprecation after configuring `deprecation_stream`"
      end
    end

    it "does not parse empty args" do
      parser = Parser.new
      expect(OptionParser).not_to receive(:new)
      parser.parse([])
    end

    it "proposes you to use --help and returns an error on incorrect argument" do
      parser = Parser.new
      option = "--my_wrong_arg"

      expect(parser).to receive(:abort) do |msg|
        expect(msg).to include('use --help', option)
      end

      parser.parse([option])
    end

    {
      '--init'         => ['-i','--I'],
      '--default-path' => ['-d'],
      '--dry-run'      => ['-d'],
      '--drb-port'     => ['-d'],
    }.each do |long, shorts|
      shorts.each do |option|
        it "won't parse #{option} as a shorthand for #{long}" do
          parser = Parser.new

          expect(parser).to receive(:abort) do |msg|
            expect(msg).to include('use --help', option)
          end

          parser.parse([option])
        end
      end
    end

    it "won't display invalid options in the help output" do
      def generate_help_text
        parser = Parser.new
        allow(parser).to receive(:exit)
        parser.parse(["--help"])
      end

      useless_lines = /^\s*--?\w+\s*$\n/

      expect { generate_help_text }.to_not output(useless_lines).to_stdout
    end

    describe "--default-path" do
      it "sets the default path where RSpec looks for examples" do
        options = Parser.parse(%w[--default-path foo])
        expect(options[:default_path]).to eq "foo"
      end
    end

    %w[--format -f].each do |option|
      describe option do
        it "defines the formatter" do
          options = Parser.parse([option, 'doc'])
          expect(options[:formatters].first).to eq(["doc"])
        end
      end
    end

    %w[--out -o].each do |option|
      describe option do
        let(:options) { Parser.parse([option, 'out.txt']) }

        it "sets the output stream for the formatter" do
          expect(options[:formatters].last).to eq(['progress', 'out.txt'])
        end

        context "with multiple formatters" do
          context "after last formatter" do
            it "sets the output stream for the last formatter" do
              options = Parser.parse(['-f', 'progress', '-f', 'doc', option, 'out.txt'])
              expect(options[:formatters][0]).to eq(['progress'])
              expect(options[:formatters][1]).to eq(['doc', 'out.txt'])
            end
          end

          context "after first formatter" do
            it "sets the output stream for the first formatter" do
              options = Parser.parse(['-f', 'progress', option, 'out.txt', '-f', 'doc'])
              expect(options[:formatters][0]).to eq(['progress', 'out.txt'])
              expect(options[:formatters][1]).to eq(['doc'])
            end
          end
        end
      end
    end

    describe "--deprecation-out" do
      it 'sets the deprecation stream' do
        options = Parser.parse(["--deprecation-out", "path/to/log"])
        expect(options).to include(:deprecation_stream => "path/to/log")
      end
    end

    %w[--example -e].each do |option|
      describe option do
        it "escapes the arg" do
          options = Parser.parse([option, "this (and that)"])
          expect(options[:full_description].length).to eq(1)
          expect("this (and that)").to match(options[:full_description].first)
        end
      end
    end

    %w[--pattern -P].each do |option|
      describe option do
        it "sets the filename pattern" do
          options = Parser.parse([option, 'spec/**/*.spec'])
          expect(options[:pattern]).to eq('spec/**/*.spec')
        end
      end
    end

    %w[--tag -t].each do |option|
      describe option do
        context "without ~" do
          it "treats no value as true" do
            options = Parser.parse([option, 'foo'])
            expect(options[:inclusion_filter]).to eq(:foo => true)
          end

          it "treats 'true' as true" do
            options = Parser.parse([option, 'foo:true'])
            expect(options[:inclusion_filter]).to eq(:foo => true)
          end

          it "treats 'nil' as nil" do
            options = Parser.parse([option, 'foo:nil'])
            expect(options[:inclusion_filter]).to eq(:foo => nil)
          end

          it "treats 'false' as false" do
            options = Parser.parse([option, 'foo:false'])
            expect(options[:inclusion_filter]).to eq(:foo => false)
          end

          it "merges muliple invocations" do
            options = Parser.parse([option, 'foo:false', option, 'bar:true', option, 'foo:true'])
            expect(options[:inclusion_filter]).to eq(:foo => true, :bar => true)
          end

          it "treats 'any_string' as 'any_string'" do
            options = Parser.parse([option, 'foo:any_string'])
            expect(options[:inclusion_filter]).to eq(:foo => 'any_string')
          end

          it "treats ':any_sym' as :any_sym" do
            options = Parser.parse([option, 'foo::any_sym'])
            expect(options[:inclusion_filter]).to eq(:foo => :any_sym)
          end

          it "treats '42' as 42" do
            options = Parser.parse([option, 'foo:42'])
            expect(options[:inclusion_filter]).to eq(:foo => 42)
          end

          it "treats '3.146' as 3.146" do
            options = Parser.parse([option, 'foo:3.146'])
            expect(options[:inclusion_filter]).to eq(:foo => 3.146)
          end
        end

        context "with ~" do
          it "treats no value as true" do
            options = Parser.parse([option, '~foo'])
            expect(options[:exclusion_filter]).to eq(:foo => true)
          end

          it "treats 'true' as true" do
            options = Parser.parse([option, '~foo:true'])
            expect(options[:exclusion_filter]).to eq(:foo => true)
          end

          it "treats 'nil' as nil" do
            options = Parser.parse([option, '~foo:nil'])
            expect(options[:exclusion_filter]).to eq(:foo => nil)
          end

          it "treats 'false' as false" do
            options = Parser.parse([option, '~foo:false'])
            expect(options[:exclusion_filter]).to eq(:foo => false)
          end
        end
      end
    end

    describe "--order" do
      it "is nil by default" do
        expect(Parser.parse([])[:order]).to be_nil
      end

      %w[rand random].each do |option|
        context "with #{option}" do
          it "defines the order as random" do
            options = Parser.parse(['--order', option])
            expect(options[:order]).to eq(option)
          end
        end
      end
    end

    describe "--seed" do
      it "sets the order to rand:SEED" do
        options = Parser.parse(%w[--seed 123])
        expect(options[:order]).to eq("rand:123")
      end
    end

    describe '--profile' do
      it 'sets profile_examples to true by default' do
        options = Parser.parse(%w[--profile])
        expect(options[:profile_examples]).to eq true
      end

      it 'sets profile_examples to supplied int' do
        options = Parser.parse(%w[--profile 10])
        expect(options[:profile_examples]).to eq 10
      end

      it 'sets profile_examples to true when accidentally combined with path' do
        allow_warning
        options = Parser.parse(%w[--profile some/path])
        expect(options[:profile_examples]).to eq true
      end

      it 'warns when accidentally combined with path' do
        expect_warning_without_call_site "Non integer specified as profile count"
        options = Parser.parse(%w[--profile some/path])
        expect(options[:profile_examples]).to eq true
      end
    end

    describe '--warning' do
      around do |ex|
        verbose = $VERBOSE
        ex.run
        $VERBOSE = verbose
      end

      it 'immediately enables warnings so that warnings are issued for files loaded by `--require`' do
        $VERBOSE = false

        expect {
          Parser.parse(%w[--warnings])
        }.to change { $VERBOSE }.from(false).to(true)
      end
    end

    describe '--exclude-dir' do
      it "adds a value to the exclude_dirs array" do
        options = Parser.parse(%w[--exclude-dir foo])
        expect(options[:exclude_dirs]).to eq ['foo']
      end

      it "can be specified multiple times to add multiple values to the exclude_dirs array" do
        options = Parser.parse(%w[--exclude-dir foo --exclude-dir bar])
        expect(options[:exclude_dirs]).to eq ['foo', 'bar']
      end
    end


  end
end
