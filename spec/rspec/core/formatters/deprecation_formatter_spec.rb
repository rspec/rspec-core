require 'spec_helper'
require 'rspec/core/formatters/deprecation_formatter'
require 'tempfile'

module RSpec::Core::Formatters
  describe DeprecationFormatter do
    let(:formatter)     { DeprecationFormatter.new(configuration) }
    let(:configuration) { double :deprecation_stream => deprecation_stream, :output_stream => summary_stream }
    let(:deprecation_stream) { StringIO.new }
    let(:summary_stream)     { StringIO.new }

    def with_start_defined_on_kernel
      return yield if ::Kernel.method_defined?(:start)

      begin
        ::Kernel.module_eval { def start(*); raise "boom"; end }
        yield
      ensure
        ::Kernel.module_eval { undef start }
      end
    end

    it 'does not blow up when `Kernel` defines `start`' do
      with_start_defined_on_kernel do
        reporter = ::RSpec::Core::Reporter.new(formatter)
        reporter.start(3)
      end
    end

    describe 'defaults when configuration has yet to be initialized' do
      let(:summary_stream)     { nil }
      let(:deprecation_stream) { nil }

      it 'has a default summary_stream of $stdout' do
        expect(formatter.summary_stream).to eq $stdout
      end

      it 'has a default deprecation_stream of $stderr' do
        expect(formatter.deprecation_stream).to eq $stderr
      end
    end

    describe '#printer' do
      context 'after configuration' do
        let(:configuration) { double :deprecation_stream => StringIO.new, :output_stream => StringIO.new }

        it 'will memorize the printer' do
          expect(formatter.printer).to eq formatter.printer
        end
      end

      context 'before configuration' do
        let(:configuration) { RSpec::Core::Configuration.new }

        it 'will not memorize the printer' do
          expect(formatter.printer).to_not eq formatter.printer
        end
      end
    end

    describe "#deprecation" do
      let(:summary_stream) { StringIO.new }

      context "with a File deprecation_stream" do
        let(:deprecation_stream) { File.open("#{Dir.tmpdir}/deprecation_summary_example_output", "w+") }

        it "prints a message if provided, ignoring other data" do
          formatter.deprecation(:message => "this message", :deprecated => "x", :replacement => "y", :call_site => "z")
          deprecation_stream.rewind
          expect(deprecation_stream.read).to eq "this message\n"
        end

        it "includes the method" do
          formatter.deprecation(:deprecated => "i_am_deprecated")
          deprecation_stream.rewind
          expect(deprecation_stream.read).to match(/i_am_deprecated is deprecated/)
        end

        it "includes the replacement" do
          formatter.deprecation(:replacement => "use_me")
          deprecation_stream.rewind
          expect(deprecation_stream.read).to match(/Use use_me instead/)
        end

        it "includes the call site if provided" do
          formatter.deprecation(:call_site => "somewhere")
          deprecation_stream.rewind
          expect(deprecation_stream.read).to match(/Called from somewhere/)
        end
      end

      context "with an IO deprecation stream" do
        let(:deprecation_stream) { StringIO.new }

        it "prints nothing" do
          5.times { formatter.deprecation(:deprecated => 'i_am_deprecated') }
          expect(deprecation_stream.string).to eq ""
        end
      end
    end

    describe "#deprecation_summary" do
      let(:summary_stream) { StringIO.new }

      context "with a File deprecation_stream" do
        let(:deprecation_stream) { File.open("#{Dir.tmpdir}/deprecation_summary_example_output", "w") }

        it "prints a count of the deprecations" do
          formatter.deprecation(:deprecated => 'i_am_deprecated')
          formatter.deprecation_summary
          expect(summary_stream.string).to match(/1 deprecation logged to .*deprecation_summary_example_output/)
        end

        it "pluralizes the reported deprecation count for more than one deprecation" do
          formatter.deprecation(:deprecated => 'i_am_deprecated')
          formatter.deprecation(:deprecated => 'i_am_deprecated_also')
          formatter.deprecation_summary
          expect(summary_stream.string).to match(/2 deprecations/)
        end

        it "is not printed when there are no deprecations" do
          formatter.deprecation_summary
          expect(summary_stream.string).to eq ""
        end
      end

      context "with an IO deprecation_stream" do
        let(:deprecation_stream) { StringIO.new }

        it "limits the deprecation warnings after 3 calls" do
          5.times { formatter.deprecation(:deprecated => 'i_am_deprecated') }
          formatter.deprecation_summary
          expected = <<-EOS.gsub(/^ {12}/, '')
            \nDeprecation Warnings:

            i_am_deprecated is deprecated.
            i_am_deprecated is deprecated.
            i_am_deprecated is deprecated.
            Too many uses of deprecated 'i_am_deprecated'. Set config.deprecation_stream to a File for full output.
          EOS
          expect(deprecation_stream.string).to eq expected
        end

        it "limits :message deprecation warnings with different callsites after 3 calls" do
          5.times do |n|
            message = "This is a long string with some callsite info: /path/#{n}/to/some/file.rb:2#{n}3.  And some more stuff can come after."
            formatter.deprecation(:message => message)
          end
          formatter.deprecation_summary
          expected = "\n" + <<-EOS.gsub(/^ {12}/, '')
            Deprecation Warnings:

            This is a long string with some callsite info: /path/0/to/some/file.rb:203.  And some more stuff can come after.
            This is a long string with some callsite info: /path/1/to/some/file.rb:213.  And some more stuff can come after.
            This is a long string with some callsite info: /path/2/to/some/file.rb:223.  And some more stuff can come after.
            Too many similar deprecation messages reported, disregarding further reports. Set config.deprecation_stream to a File for full output.
          EOS
          expect(deprecation_stream.string).to eq expected
        end

        it "prints the true deprecation count to the summary_stream" do
          5.times { formatter.deprecation(:deprecated => 'i_am_deprecated') }
          5.times do |n|
            formatter.deprecation(:message => "callsite info: /path/#{n}/to/some/file.rb:2#{n}3.  And some more stuff")
          end
          formatter.deprecation_summary
          expect(summary_stream.string).to match(/10 deprecation warnings total/)
        end
      end
    end
  end
end
