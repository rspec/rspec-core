if defined?(ErrorHighlight)
  class DummyErrorHighlightFormatter
    def self.message_for(spot)
      ""
    end
  end

  RSpec.configure do |c|
    c.around(:disable_error_highlight => true) do |ex|
      begin
        old_formatter = ErrorHighlight.formatter
        ErrorHighlight.formatter = DummyErrorHighlightFormatter
        ex.run
      ensure
        ErrorHighlight.formatter = old_formatter
      end
    end
  end
end
