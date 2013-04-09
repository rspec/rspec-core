module RSpec
  module Core
    module Extensions
      # @private
      module InstanceEvalWithArgs
        # @private
        #
        # Used internally to support `instance_exec` in Ruby 1.8.6.
        #
        # based on Bounded Spec InstanceExec (Mauricio Fernandez)
        # http://eigenclass.org/hiki/bounded+space+instance_exec
        # - uses singleton_class instead of global InstanceExecHelper module
        # - this keeps it scoped to classes/modules that include this module
        # - only necessary for ruby 1.8.6
        def instance_eval_with_args(*args, &block)
          instance_exec(*args, &block)
        end
      end
    end
  end
end
