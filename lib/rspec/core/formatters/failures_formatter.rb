require 'rspec/core/formatters/base_formatter'

module RSpec
  module Core
    module Formatters
      class FailuresFormatter < BaseFormatter

        def example_failed(example)
          output.puts retry_command(example)
        end

        def retry_command(example)
          example_name = example.full_description.gsub(%q{'}) { |c| %q{\'} }
          "-e '#{example_name}'"
        end
      end
    end
  end
end
