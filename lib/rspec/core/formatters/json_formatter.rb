RSpec::Support.require_rspec_core "formatters/base_formatter"
require 'json'

module RSpec
  module Core
    module Formatters
      # @private
      class JsonFormatter < BaseFormatter
        Formatters.register self, :message, :dump_summary, :stop, :close,
                                  :dump_profile

        attr_reader :output_hash

        def initialize(output)
          super
          @output_hash = {}
        end

        def message(notification)
          (@output_hash[:messages] ||= []) << notification.message
        end

        def dump_summary(summary)
          @output_hash[:summary] = {
            :duration => summary.duration,
            :example_count => summary.example_count,
            :failure_count => summary.failure_count,
            :pending_count => summary.pending_count
          }
          @output_hash[:summary_line] = summary.summary_line

          dump_profile unless mute_profile_output?(summary.failure_count)
        end

        def stop(notification)
          @output_hash[:examples] = examples.map do |example|
            format_example(example).tap do |hash|
              if e=example.exception
                hash[:exception] =  {
                  :class => e.class.name,
                  :message => e.message,
                  :backtrace => e.backtrace,
                }
              end
            end
          end
        end

        def close(notification)
          output.write @output_hash.to_json
          output.close if IO === output && output != $stdout
        end

        def dump_profile
          @output_hash[:profile] = {}
          dump_profile_slowest_examples
          dump_profile_slowest_example_groups
        end

        # @api private
        def dump_profile_slowest_examples
          @output_hash[:profile] = {}
          sorted_examples = slowest_examples
          @output_hash[:profile][:examples] = sorted_examples[:examples].map do |example|
            format_example(example).tap do |hash|
              hash[:run_time] = example.execution_result[:run_time]
            end
          end
          @output_hash[:profile][:slowest] = sorted_examples[:slows]
          @output_hash[:profile][:total] = sorted_examples[:total]
        end

        # @api private
        def dump_profile_slowest_example_groups
          @output_hash[:profile] ||= {}
          @output_hash[:profile][:groups] = slowest_groups.map do |loc, hash|
            hash.update(:location => loc)
          end
        end

      private

        def format_example(example)
          {
            :description => example.description,
            :full_description => example.full_description,
            :status => example.execution_result[:status],
            :file_path => example.metadata[:file_path],
            :line_number  => example.metadata[:line_number],
            :run_time => example.execution_result[:run_time]
          }
        end
      end
    end
  end
end
