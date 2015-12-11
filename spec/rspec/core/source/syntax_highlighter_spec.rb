require 'rspec/core/source/syntax_highlighter'

class RSpec::Core::Source
  RSpec.describe SyntaxHighlighter do
    let(:config)      { RSpec::Core::Configuration.new.tap { |c| c.color = true } }
    let(:highlighter) { SyntaxHighlighter.new(config)  }

    def be_highlighted
      include("\e[32m")
    end

    context "when CodeRay is available", :unless => RSpec::Support::OS.windows? do
      before { expect { require 'coderay' }.not_to raise_error }

      it 'highlights the syntax of the provided lines' do
        highlighted = highlighter.highlight(['[:ok, "ok"]'])
        expect(highlighted.size).to eq(1)
        expect(highlighted.first).to be_highlighted.and include(":ok")
      end

      it 'prefixes the each line with a reset escape code so it can be interpolated in a colored string without affecting the syntax highlighting of the snippet' do
        highlighted = highlighter.highlight(['a = 1', 'b = 2'])
        expect(highlighted).to all start_with("\e[0m")
      end

      it 'leaves leading spaces alone so it can be re-indented as needed without the leading reset code interfering' do
        highlighted = highlighter.highlight(['  a = 1', '  b = 2'])
        expect(highlighted).to all start_with("  \e[0m")
      end

      it 'returns the provided lines unmodified if color is disabled' do
        config.color = false
        expect(highlighter.highlight(['[:ok, "ok"]'])).to eq(['[:ok, "ok"]'])
      end

      it 'dynamically adjusts to changing color config' do
        config.color = false
        expect(highlighter.highlight(['[:ok, "ok"]']).first).not_to be_highlighted
        config.color = true
        expect(highlighter.highlight(['[:ok, "ok"]']).first).to be_highlighted
        config.color = false
        expect(highlighter.highlight(['[:ok, "ok"]']).first).not_to be_highlighted
      end

      it 'notifies the reporter' do
        config.reporter.syntax_highlighting_unavailable = true

        expect {
          highlighter.highlight([""])
        }.to change { config.reporter.syntax_highlighting_unavailable }.to(false)
      end

      it 'does not notify the reporter if highlighting is never attempted' do
        config.reporter.syntax_highlighting_unavailable = true

        expect {
          SyntaxHighlighter.new(config)
        }.not_to change { config.reporter.syntax_highlighting_unavailable }
      end

      it "rescues coderay failures since we do not want a coderay error to be displayed instead of the user's error" do
        allow(CodeRay).to receive(:encode).and_raise(Exception.new "boom")
        lines = [":ok"]
        expect(highlighter.highlight(lines)).to eq(lines)
      end
    end

    context "when CodeRay is unavailable" do
      before do
        allow(::Kernel).to receive(:require).with("coderay").and_raise(LoadError)
      end

      it 'does not highlight the syntax' do
        unhighlighted = highlighter.highlight(['[:ok, "ok"]'])
        expect(unhighlighted.size).to eq(1)
        expect(unhighlighted.first).not_to be_highlighted
      end

      it 'does not mutate the input array' do
        lines = ["a = 1", "b = 2"]
        expect { highlighter.highlight(lines) }.not_to change { lines }
      end

      it 'does not add the comment about coderay if the snippet is only one line as we do not want to convert it to multiline just for the comment' do
        expect(highlighter.highlight(["a = 1"])).to eq(["a = 1"])
      end

      it 'does not add the comment about coderay if given no lines' do
        expect(highlighter.highlight([])).to eq([])
      end

      it 'does not add the comment about coderay if color id disabled even when given a multiline snippet' do
        config.color = false
        lines = ["a = 1", "b = 2"]
        expect(highlighter.highlight(lines)).to eq(lines)
      end

      it 'notifies the reporter', :unless => RSpec::Support::OS.windows? do
        config.reporter.syntax_highlighting_unavailable = false

        expect {
          highlighter.highlight([""])
        }.to change { config.reporter.syntax_highlighting_unavailable }.to(true)
      end

      it 'does not notify the reporter if highlighting is never attempted' do
        config.reporter.syntax_highlighting_unavailable = false

        expect {
          SyntaxHighlighter.new(config)
        }.not_to change { config.reporter.syntax_highlighting_unavailable }
      end
    end
  end
end
