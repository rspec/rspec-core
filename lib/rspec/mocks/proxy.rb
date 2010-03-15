module Rspec
  module Mocks
    class Proxy
      DEFAULT_OPTIONS = { :null_object => false }

      class << self
        def warn_about_expectations_on_nil
          defined?(@warn_about_expectations_on_nil) ? @warn_about_expectations_on_nil : true
        end
      
        def warn_about_expectations_on_nil=(new_value)
          @warn_about_expectations_on_nil = new_value
        end
      
        def allow_message_expectations_on_nil
          @warn_about_expectations_on_nil = false
          
          # ensure nil.rspec_verify is called even if an expectation is not set in the example
          # otherwise the allowance would effect subsequent examples
          $rspec_mocks.add(nil) unless $rspec_mocks.nil?
        end

        def allow_message_expectations_on_nil?
          !warn_about_expectations_on_nil
        end
      end

      def initialize(target, name=nil, options={})
        @target = target
        @name = name
        @error_generator = ErrorGenerator.new target, name
        @expectation_ordering = OrderGroup.new @error_generator
        @messages_received = []
        @options = options ? DEFAULT_OPTIONS.dup.merge(options) : DEFAULT_OPTIONS
        @already_proxied_respond_to = false
      end

      attr_accessor :already_proxied_respond_to

      def null_object?
        @options[:null_object]
      end
      
      def as_null_object
        @options[:null_object] = true
        @target
      end

      def add_message_expectation(expected_from, sym, opts={}, &block)        
        __add sym
        expectation = if existing_stub = expectations_hash[sym][:stubs].detect {|s| s.sym == sym }
          existing_stub.build_child(expected_from, block_given?? block : nil, 1, opts)
        else
          MessageExpectation.new(@error_generator, @expectation_ordering, expected_from, sym, block_given? ? block : nil, 1, opts)
        end
        expectations_hash[sym].add_expectation expectation
      end

      def add_negative_message_expectation(expected_from, sym, &block)
        __add sym
        expectations_hash[sym].add_expectation NegativeMessageExpectation.new(@error_generator, @expectation_ordering, expected_from, sym, block_given? ? block : nil)
      end

      def add_stub(expected_from, sym, opts={}, &implementation)
        __add sym
        expectations_hash[sym].add_stub MessageExpectation.new(@error_generator, @expectation_ordering, expected_from, sym, nil, :any, opts, &implementation)
      end
      
      def verify #:nodoc:
        method_doubles.each {|d| d.verify}
      ensure
        reset
      end

      def reset
        method_doubles.each {|d| d.reset}
        reset_nil_expectations_warning
      end

      def received_message?(sym, *args, &block)
        @messages_received.any? {|array| array == [sym, args, block]}
      end

      def has_negative_expectation?(sym)
        double_for(sym)[:expectations].detect {|expectation| expectation.negative_expectation_for?(sym)}
      end
      
      def record_message_received(sym, args, block)
        @messages_received << [sym, args, block]
      end

      def message_received(sym, *args, &block)
        expectation = find_matching_expectation(sym, *args)
        stub = find_matching_method_stub(sym, *args)

        if (stub && expectation && expectation.called_max_times?) || (stub && !expectation)
          if expectation = find_almost_matching_expectation(sym, *args)
            expectation.advise(args, block) unless expectation.expected_messages_received?
          end
          stub.invoke(args, block)
        elsif expectation
          expectation.invoke(args, block)
        elsif expectation = find_almost_matching_expectation(sym, *args)
          expectation.advise(args, block) if null_object? unless expectation.expected_messages_received?
          raise_unexpected_message_args_error(expectation, *args) unless (has_negative_expectation?(sym) or null_object?)
        elsif @target.is_a?(Class)
          @target.superclass.send(sym, *args, &block)
        else
          @target.__send__ :method_missing, sym, *args, &block
        end
      end

      def raise_unexpected_message_args_error(expectation, *args)
        @error_generator.raise_unexpected_message_args_error(expectation, *args)
      end

      def raise_unexpected_message_error(sym, *args)
        @error_generator.raise_unexpected_message_error sym, *args
      end
      
    private

      def __add(sym)
        $rspec_mocks.add(@target) if $rspec_mocks
        double_for(sym).proxy_method
      end
      
      def double_for(sym)
        expectations_hash[sym]
      end
      
      def method_doubles
        expectations_hash.values
      end
      
      def proxy_for_nil_class?
        @target.nil?
      end
      
      def reset_nil_expectations_warning
        self.class.warn_about_expectations_on_nil = true if proxy_for_nil_class?
      end

      def find_matching_expectation(sym, *args)
        double_for(sym)[:expectations].find {|expectation| expectation.matches(sym, args) && !expectation.called_max_times?} || 
        double_for(sym)[:expectations].find {|expectation| expectation.matches(sym, args)}
      end

      def find_almost_matching_expectation(sym, *args)
        double_for(sym)[:expectations].find {|expectation| expectation.matches_name_but_not_args(sym, args)}
      end

      def find_matching_method_stub(sym, *args)
        double_for(sym)[:stubs].find {|stub| stub.matches(sym, args)}
      end

      def expectations_hash
        @expectations_hash ||= Hash.new {|h,k|
          h[k] = MethodDouble.new(@target, k, self)
        }
      end

      class MethodDouble < Hash
        def initialize(target, sym, proxy)
          @target = target
          @sym = sym
          @proxy = proxy
          @proxied = false
          store(:expectations, [])
          store(:stubs, [])
        end

        def visibility
          if Mock === @target
            'public'
          elsif target_metaclass.private_method_defined?(@sym)
            'private'
          elsif target_metaclass.protected_method_defined?(@sym)
            'protected'
          else
            'public'
          end
        end

        def target_metaclass
          class << @target; self; end
        end

        def munge(sym)
          "proxied_by_rspec__#{sym}"
        end

        def munged_sym
          munge(@sym)
        end

        def target_responds_to?(sym)
          return @target.__send__(munge(:respond_to?),sym) if @proxy.already_proxied_respond_to
          return @proxy.already_proxied_respond_to = true if sym == :respond_to?
          return @target.respond_to?(sym, true)
        end

        def define_munged
          munged = munged_sym
          orig = @sym
          target_metaclass.instance_eval do
            alias_method(munged, orig) if method_defined?(orig)
          end
        end

        def redefine
          sym = @sym
          visibility_string = "#{visibility} :#{sym}"
          target_metaclass.class_eval(<<-EOF, __FILE__, __LINE__)
            def #{sym}(*args, &block)
              __mock_proxy.message_received :#{sym}, *args, &block
            end
            #{visibility_string}
          EOF
        end

        def proxied?
          @proxied
        end

        def proxy_method
          if target_responds_to?(@sym)
            @proxied = true
            define_munged
          end
          redefine
          warn_if_nil_class
        end

        def reset_proxied_method
          if proxied?
            sym = @sym
            munged_sym = self.munged_sym
            target_metaclass.instance_eval do
              remove_method sym
              if method_defined?(munged_sym)
                alias_method sym, munged_sym
                remove_method munged_sym
              end
            end
            @proxied = false
          end
        end

        def verify
          self[:expectations].each do |expectation|
            expectation.verify_messages_received
          end
        end

        def reset
          reset_proxied_method
          clear
        end

        def clear
          self[:expectations].clear
          self[:stubs].clear
        end

        def add_expectation(expectation)
          self[:expectations] << expectation
          expectation
        end

        def add_stub(stub)
          self[:stubs] << stub
          stub
        end

        def proxy_for_nil_class?
          @target.nil?
        end

        def warn_if_nil_class
          if proxy_for_nil_class? & Rspec::Mocks::Proxy.warn_about_expectations_on_nil
            Kernel.warn("An expectation of :#{@sym} was set on nil. Called from #{caller[4]}. Use allow_message_expectations_on_nil to disable warnings.")
          end
        end

      end

    end
  end
end
