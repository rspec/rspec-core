require 'rspec/core/formatters/base_formatter'

require 'builder'
require 'time'

# Dumps rspec results as a JUnit XML file.
# Based on XML schema: http://windyroad.org/dl/Open%20Source/JUnit.xsd
module RSpec
  module Core
    module Formatters

      class JUnitFormatter < BaseFormatter
        def start example_count
          @start = Time.now
          super
        end

        def dump_summary duration, example_count, failure_count, pending_count
          super
  
          xml.instruct!
          xml.testsuite :tests => example_count, :failures => failure_count, :errors => 0, :time => '%.6f' % duration, :timestamp => @start.iso8601 do
            xml.properties
            examples.each do |example|
              send :"dump_summary_example_#{example.execution_result[:status]}", example
            end
          end
        end

        def xml_example example, &block
          xml.testcase :classname => example.file_path, :name => example.full_description, :time => '%.6f' % example.execution_result[:run_time], &block
        end

        def dump_summary_example_passed example
          xml_example example
        end

        def dump_summary_example_pending example
          xml_example example do
            xml.skipped
          end
        end

        def dump_summary_example_failed example
          exception = example.execution_result[:exception]
          backtrace = format_backtrace exception.backtrace, example
  
          xml_example example do
            xml.failure :message => exception.to_s, :type => exception.class.name do
              xml.cdata! "#{exception.message}\n#{backtrace.join "\n"}"
            end
          end
        end

      protected

        def xml
          @xml ||= Builder::XmlMarkup.new :target => output, :indent => 2 
        end
      end

    end
  end
end
