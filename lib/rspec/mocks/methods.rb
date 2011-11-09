module RSpec
  module Mocks
    # Methods that are added to every object.
    module Methods
      # Sets and expectation that this object should receive a message before
      # the end of the example.
      def should_receive(message, opts={}, &block)
        __mock_proxy.add_message_expectation(opts[:expected_from] || caller(1)[0], message.to_sym, opts, &block)
      end

      # Sets and expectation that this object should _not_ receive a message
      # during this example.
      def should_not_receive(message, &block)
        __mock_proxy.add_negative_message_expectation(caller(1)[0], message.to_sym, &block)
      end

      # Tells the object to respond to the message with a canned value
      #
      # ## Examples
      #     counter.stub(:count).and_return(37)
      #     counter.stub(:count => 37)
      #     counter.stub(:count) { 37 }
      def stub(message_or_hash, opts={}, &block)
        if Hash === message_or_hash
          message_or_hash.each {|message, value| stub(message).and_return value }
        else
          __mock_proxy.add_stub(caller(1)[0], message_or_hash.to_sym, opts, &block)
        end
      end

      # Removes a stub. On a double, the object will no longer respond to
      # +message+. On a real object, the original method (if it exists) is
      # restored.
      #
      # This is rarely used, but can be useful when a stub is set up during a
      # shared `before` hook for the common case, but you want to replace it
      # for a special case.
      def unstub(message)
        __mock_proxy.remove_stub(message)
      end

      alias_method :stub!, :stub
      alias_method :unstub!, :unstub

      # Stubs a chain of methods. Especially useful with fluent and/or
      # composable interfaces.
      #
      # ## Examples
      #
      #   double.stub_chain("foo.bar") { :baz }
      #   double.stub_chain(:foo, :bar) { :baz }
      #   Article.stub_chain("recent.published") { [Article.new] }
      def stub_chain(*chain, &blk)
        chain, blk = format_chain(*chain, &blk)
        if chain.length > 1
          if matching_stub = __mock_proxy.__send__(:find_matching_method_stub, chain[0].to_sym)
            chain.shift
            matching_stub.invoke.stub_chain(*chain, &blk)
          else
            next_in_chain = Object.new
            stub(chain.shift) { next_in_chain }
            next_in_chain.stub_chain(*chain, &blk)
          end
        else
          stub(chain.shift, &blk)
        end
      end

      # Tells the object to respond to all messages. If specific stub values
      # are declared, they'll work as expected. If not, the receiver is
      # returned.
      def as_null_object
        __mock_proxy.as_null_object
      end

      # Returns true if this object has received `as_null_object`
      def null_object?
        __mock_proxy.null_object?
      end

      # @api private
      def received_message?(sym, *args, &block)
        __mock_proxy.received_message?(sym.to_sym, *args, &block)
      end

      # @api private
      def rspec_verify
        __mock_proxy.verify
      end

      # @api private
      def rspec_reset
        __mock_proxy.reset
      end

    private

      def __mock_proxy
        @mock_proxy ||= begin
          mp = if Mock === self
            Proxy.new(self, @name, @options)
          else
            Proxy.new(self)
          end

          Serialization.fix_for(self)
          mp
        end
      end

      def format_chain(*chain, &blk)
        if Hash === chain.last
          hash = chain.pop
          hash.each do |k,v|
            chain << k
            blk = lambda { v }
          end
        end
        return chain.join('.').split('.'), blk
      end
    end
  end
end
