module RSpec
  module Core
    module Manual
      class ManualDeclaredInExample < StandardError; end

      NO_REASON_GIVEN = 'Manual test'
      MANUAL_TEST = 'Manual test'

      def manual(*args)
        return self.class.before(:each) { manual(*args) } unless example

        options = args.last.is_a?(Hash) ? args.pop : {}
        message = args.first || NO_REASON_GIVEN

        if options[:unless] || (options.has_key?(:if) && !options[:if])
          return block_given? ? yield : nil
        end

        example.metadata[:manual] = true
        example.metadata[:execution_result][:manual_message] = message
        if block_given?
          begin
            result = begin
                       yield
                       example.example_group_instance.instance_eval { verify_mocks_for_rspec }
                     end
            example.metadata[:manual] = false
          rescue Exception => e
            example.execution_result[:exception] = e
          ensure
            teardown_mocks_for_rspec
          end
          #raise ManualExampleFixedError.new if result
        end
        raise ManualDeclaredInExample.new(message)
      end
    end
  end
end
