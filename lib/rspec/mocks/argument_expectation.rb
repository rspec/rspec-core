module RSpec
  module Mocks
    class ArgumentExpectation
      attr_reader :args
      
      def initialize(*args, &block)
        @args = args
        @matchers_block = args.empty? ? block : nil
        @match_any_args = false
        @matchers = nil
        
        case args.first
        when ArgumentMatchers::AnyArgsMatcher
          @match_any_args = true
        when ArgumentMatchers::NoArgsMatcher
          @matchers = []
        else
          @matchers = args.collect {|arg| matcher_for(arg)}
        end
      end
      
      def matcher_for(arg)
        return ArgumentMatchers::MatcherMatcher.new(arg) if is_matcher?(arg)
        return ArgumentMatchers::RegexpMatcher.new(arg)  if arg.is_a?(Regexp)
        return ArgumentMatchers::EqualityProxy.new(arg)
      end
      
      def is_matcher?(obj)
        !is_stub_as_null_object?(obj) & obj.respond_to?(:matches?) & obj.respond_to?(:description)
      end

      def is_stub_as_null_object?(obj)
        obj.respond_to?(:__rspec_double_acting_as_null_object?) && obj.__rspec_double_acting_as_null_object?
      end
      
      def args_match?(*args)
        match_any_args? || matchers_block_matches?(*args) || matchers_match?(*args)
      end
      
      def matchers_block_matches?(*args)
        @matchers_block ? @matchers_block.call(*args) : nil
      end
      
      def matchers_match?(*args)
        @matchers == args
      end
      
      def match_any_args?
        @match_any_args
      end
    end
  end
end
