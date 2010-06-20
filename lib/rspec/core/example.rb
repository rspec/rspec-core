module RSpec
  module Core
    class Example
      RSpec.subscribe(:example_initialized) {|e| e.example.in_block = true}
      RSpec.subscribe(:example_executed) {|e| e.example.in_block = false}

      attr_reader :metadata, :example_block, :options
      attr_accessor :in_block
      
      def in_block?
        !!in_block
      end

      def self.delegate_to_metadata(*keys)
        keys.each do |key|
          define_method(key) {@metadata[key]}
        end
      end

      delegate_to_metadata :description, :full_description, :execution_result, :file_path, :pending

      alias_method :inspect, :full_description
      alias_method :to_s, :full_description

      def initialize(example_group_class, desc, options, example_block=nil)
        @example_group_class, @options, @example_block = example_group_class, options, example_block
        @metadata = @example_group_class.metadata.for_example(desc, options)
      end

      def example_group
        @example_group_class
      end

      def specifies_attribute?
        in_block && metadata[:attribute_of_subject]
      end

      alias_method :behaviour, :example_group

      def run(example_group_instance, reporter)
        @example_group_instance = example_group_instance
        @example_group_instance.example = self

        run_started

        exception = nil

        begin
          reporter.example_started(@example_group_instance)
          run_before_each
          reporter.example_initialized(@example_group_instance)
          pending_declared_in_example = catch(:pending_declared_in_example) do
            if @example_group_class.hooks[:around][:each].empty?
              @example_group_instance.instance_eval(&example_block) unless pending
            else
              @example_group_class.hooks[:around][:each].first.call(AroundProxy.new(self, &example_block))
            end
            throw :pending_declared_in_example, false
          end
        rescue Exception => e
          exception = e
        ensure
          reporter.example_executed(@example_group_instance)
          assign_auto_description
        end

        begin
          run_after_each
        rescue Exception => e
          exception ||= e
        ensure
          @example_group_instance.example = nil
        end

        if exception
          run_failed(reporter, exception) 
        elsif pending_declared_in_example
          run_pending(reporter, pending_declared_in_example)
        elsif pending
          run_pending(reporter, 'Not Yet Implemented')
        else
          run_passed(reporter) 
        end
      end

    private

      def run_started
        record_results :started_at => Time.now
      end

      def run_passed(reporter=nil)
        run_finished reporter, 'passed'
        true
      end

      def run_pending(reporter, message)
        run_finished reporter, 'pending', :pending_message => message
        true
      end

      def run_failed(reporter, exception)
        run_finished reporter, 'failed', :exception_encountered => exception
        false
      end

      def run_finished(reporter, status, results={})
        record_results results.update(:status => status)
        finish_time = Time.now
        record_results :finished_at => finish_time, :run_time => (finish_time - execution_result[:started_at])
        reporter.example_finished(self)
      end

      def run_before_each
        @example_group_class.eval_before_eachs(@example_group_instance)
      end

      def run_after_each
        @example_group_class.eval_after_eachs(@example_group_instance)
      end

      def assign_auto_description
        if description.empty?
          metadata[:description] = RSpec::Matchers.generated_description 
          RSpec::Matchers.clear_generated_description
        end
      end

      def record_results(results={})
        execution_result.update(results)
      end
    end
  end
end
