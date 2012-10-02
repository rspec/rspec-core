require 'rspec/core/formatters/base_text_formatter'
module RSpec
  module Core
    module Formatters

      class ProgressFormatter < BaseTextFormatter

        def example_passed(example)
          super(example)
          output.print green('.')
        end

        def example_pending(example)
          super(example)
          output.print yellow('*')
        end
        
        # 09/14/2012 rgunter
        def example_manual(example)
          super(example)
          output.print blue('*')
        end

        def example_failed(example)
          super(example)
          output.print red('F')
        end

        def start_dump
          super()
          output.puts
        end

      end

    end
  end
end
