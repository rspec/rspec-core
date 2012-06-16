require 'irb'

module RSpec
  module Core
    module IrbExtension
      def new(workspace = nil, *args)
        workspace ||= ::IRB::WorkSpace.new(Debugger.irb_binding)
        super(workspace, *args)
      end

      ::IRB::Irb.extend self
    end

    module Debugger
      extend self
      attr_accessor :irb_binding

      def start(binding, breakpoint)
        explain(breakpoint)

        with_binding binding do
          ::IRB.start
        end
      end

    private

      def explain(breakpoint)
        out.puts <<-EOS.gsub(/^\s*\|/, '')
          |
          |*****************************************************************
          |A `debugger` statement has been encountered but ruby-debug is not
          |loaded. For a full debugger, install `ruby-debug` and use the -d
          |or --debug option.
          |
          |The `debugger` statement was encounted at:
          |#{breakpoint}
          |
          |#{listing(breakpoint)}
          |
          |We've setup an IRB sessionso you can poke around here
          |a bit. Type `exit` to continue.
          |*****************************************************************
          |
        EOS
      end

      def with_binding(binding)
        self.irb_binding = binding
        yield
      ensure
        self.irb_binding = nil
      end

      NUM_LINES = 11 # 5 on either side of the breakpoint

      def listing(breakpoint)
        file, line_num, *rest = breakpoint.split(':')
        line_num = line_num.to_i
        start_line = [line_num - 6, 1].max

        lines = File.read(file).lines.to_a[start_line, NUM_LINES]

        prefixes = (start_line...(start_line + NUM_LINES)).map do |num|
          num += 1
          arrow = (num == line_num) ? " => " : "    "
          arrow + num.to_s.rjust(4)
        end

        prefixes.zip(lines).map do |(prefix, line)|
          prefix + line
        end.join("\n|")
      end

      def out
        RSpec.configuration.error_stream || $stderr
      end
    end
  end
end

