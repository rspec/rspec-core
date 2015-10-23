RSpec::Support.require_rspec_core 'source/node'
RSpec::Support.require_rspec_core 'source/token'

module RSpec
  module Core
    # @private
    # Represents a Ruby source file and provides access to AST and tokens.
    class Source
      attr_reader :source, :path

      def self.from_file(path)
        source = File.read(path)
        new(source, path)
      end

      def initialize(source_string, path=nil)
        @source = source_string
        @path = path ? File.expand_path(path) : '(string)'
      end

      def lines
        @lines ||= source.split("\n")
      end

      def ast
        @ast ||= begin
          require 'ripper'
          sexp = Ripper.sexp(source)
          Node.new(sexp)
        end
      end

      def tokens
        @tokens ||= begin
          require 'ripper'
          tokens = Ripper.lex(source)
          Token.tokens_from_ripper_tokens(tokens)
        end
      end

      def nodes_by_line_number
        @nodes_by_line_number ||= begin
          nodes_by_line_number = ast.select(&:location).group_by { |node| node.location.line }
          Hash.new { |hash, key| hash[key] = [] }.merge(nodes_by_line_number)
        end
      end

      def tokens_by_line_number
        @tokens_by_line_number ||= begin
          nodes_by_line_number = tokens.group_by { |token| token.location.line }
          Hash.new { |hash, key| hash[key] = [] }.merge(nodes_by_line_number)
        end
      end

      def inspect
        "#<#{self.class} #{path}>"
      end

      # @private
      class Cache
        def initialize
          @sources_by_path = {}
        end

        def source_from_file(path)
          @sources_by_path[path] ||= Source.from_file(path)
        end
      end
    end
  end
end