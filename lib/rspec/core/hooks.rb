module RSpec
  module Core
    # Hooks
    module Hooks
      # @api public
      # @overload before(&block)
      # @overload before(scope, &block)
      # @overload before(scope, conditions, &block)
      # @overload before(conditions, &block)
      #
      # @option [Symbol] scope `:each`, `:all`, or `:suite` (defaults to `:each`)
      # @option [Hash] conditions
      #   constrains this hook to examples matching these conditions e.g.
      #   `before(:each, :ui => true) { ... }` will only run with examples or
      #   groups declared with `:ui => true`.
      #
      # @see #after
      # @see #around
      # @see ExampleGroup
      # @see SharedContext
      # @see SharedExampleGroup
      # @see Configuration
      #
      # Declare a block of code to be run before each example (using `:each`)
      # or once before any example (using `:all`). These are usually declared
      # directly in the {ExampleGroup} to which they apply, but they can also
      # be shared across multiple groups.
      #
      # You can also use `before(:suite)` to run a block of code before any
      # example groups are run. This should be declared in {RSpec.configure}
      #
      # Instance variables declared in `before(:each)` or `before(:all)` are
      # accessible within each example.
      #
      # ### Order
      #
      # `before` hooks are stored in three scopes, which are run in order:
      # `:suite`, `:all`, and `:each`. They can also be declared in several
      # different places: `RSpec.configure`, a parent group, the current group.
      # They are run in the following order:
      #
      #     before(:suite) # declared in RSpec.configure
      #     before(:all)   # declared in RSpec.configure
      #     before(:all)   # declared in a parent group
      #     before(:all)   # declared in the current group
      #     before(:each)  # declared in RSpec.configure
      #     before(:each)  # declared in a parent group
      #     before(:each)  # declared in the current group
      #
      # If more than one `before` is declared within any one scope, they are run
      # in the order in which they are declared.
      #
      # ### Conditions
      #
      # When you add a conditions hash to `before(:each)` or `before(:all)`,
      # RSpec will only apply that hook to groups or examples that match the
      # conditions. e.g.
      #
      #     RSpec.configure do |config|
      #       config.before(:each, :authorized => true) do
      #         log_in_as :authorized_user
      #       end
      #     end
      #
      #     describe Something, :authorized => true do
      #       # the before hook will run in before each example in this group
      #     end
      #
      #     describe SomethingElse do
      #       it "does something", :authorized => true do
      #         # the before hook will run before this example
      #       end
      #
      #       it "does something else" do
      #         # the hook will not run before this example
      #       end
      #     end
      #
      # ### Warning: `before(:suite, :with => :conditions)`
      #
      # The conditions hash is used to match against specific examples. Since
      # `before(:suite)` is not run in relation to any specific example or
      # group, conditions passed along with `:suite` are effectively ignored.
      #
      # ### Exceptions
      #
      # When an exception is raised in a `before` block, RSpec skips any
      # subsequent `before` blocks and the example, but runs all of the
      # `after(:each)` and `after(:all)` hooks.
      #
      # ### Warning: implicit before blocks
      #
      # `before` hooks can also be declared in shared contexts which get
      # included implicitly either by you or by extension libraries. Since
      # RSpec runs these in the order in which they are declared within each
      # scope, load order matters, and can lead to confusing results when one
      # before block depends on state that is prepared in another before block
      # that gets run later.
      #
      # ### Warning: `before(:all)`
      #
      # It is very tempting to use `before(:all)` to speed things up, but we
      # recommend that you avoid this as there are a number of gotchas, as well
      # as things that simply don't work.
      #
      # #### context
      #
      # `before(:all)` is run in an example that is generated to provide group
      # context for the block.
      #
      # #### instance variables
      #
      # Instance variables declared in `before(:all)` are shared across all the
      # examples in the group.  This means that each example can change the
      # state of a shared object, resulting in an ordering dependency that can
      # make it difficult to reason about failures.
      #
      # #### unsupported rspec constructs
      #
      # RSpec has several constructs that reset state between each example
      # automatically. These are not intended for use from within `before(:all)`:
      #
      #   * `let` declarations
      #   * `subject` declarations
      #   * Any mocking, stubbing or test double declaration
      #
      # ### other frameworks
      #
      # Mock object frameworks and database transaction managers (like
      # ActiveRecord) are typically designed around the idea of setting up
      # before an example, running that one example, and then tearing down.
      # This means that mocks and stubs can (sometimes) be declared in
      # `before(:all)`, but get torn down before the first real example is ever
      # run.
      #
      # You _can_ create database-backed model objects in a `before(:all)` in
      # rspec-rails, but it will not be wrapped in a transaction for you, so
      # you are on your own to clean up in an `after(:all)` block.
      #
      # @example before(:each) declared in an {ExampleGroup}
      #
      #     describe Thing do
      #       before(:each) do
      #         @thing = Thing.new
      #       end
      #
      #       it "does something" do
      #         # here you can access @thing
      #       end
      #     end
      #
      # @example before(:all) declared in an {ExampleGroup}
      #
      #     describe Parser do
      #       before(:all) do
      #         File.open(file_to_parse, 'w') do |f|
      #           f.write <<-CONTENT
      #             stuff in the file
      #           CONTENT
      #         end
      #       end
      #
      #       it "parses the file" do
      #         Parser.parse(file_to_parse)
      #       end
      #
      #       after(:all) do
      #         File.delete(file_to_parse)
      #       end
      #     end
      def before(*args, &block)
        hooks.register :append, :before, *args, &block
      end

      alias_method :append_before, :before

      # Adds `block` to the front of the list of `before` blocks in the same
      # scope (`:each`, `:all`, or `:suite`).
      #
      # See #before for scoping semantics.
      def prepend_before(*args, &block)
        hooks.register :prepend, :before, *args, &block
      end

      # @api public
      # @overload after(&block)
      # @overload after(scope, &block)
      # @overload after(scope, conditions, &block)
      # @overload after(conditions, &block)
      #
      # @option [Symbol] scope `:each`, `:all`, or `:suite` (defaults to `:each`)
      # @option [Hash] conditions
      #   constrains this hook to examples matching these conditions e.g.
      #   `after(:each, :ui => true) { ... }` will only run with examples or
      #   groups declared with `:ui => true`.
      #
      # @see #before
      # @see #around
      # @see ExampleGroup
      # @see SharedContext
      # @see SharedExampleGroup
      # @see Configuration
      #
      # Declare a block of code to be run after each example (using `:each`) or
      # once after all examples (using `:all`). See
      # [#before](Hooks#before-instance_method) for more information about
      # ordering.
      #
      # ### Exceptions
      #
      # `after` hooks are guaranteed to run even when there are exceptions in
      # `before` hooks or examples.  When an exception is raised in an after
      # block, the exception is captured for later reporting, and subsequent
      # `after` blocks are run.
      #
      # ### Order
      #
      # `after` hooks are stored in three scopes, which are run in order:
      # `:each`, `:all`, and `:suite`. They can also be declared in several
      # different places: `RSpec.configure`, a parent group, the current group.
      # They are run in the following order:
      #
      #     after(:each) # declared in the current group
      #     after(:each) # declared in a parent group
      #     after(:each) # declared in RSpec.configure
      #     after(:all)  # declared in the current group
      #     after(:all)  # declared in a parent group
      #     after(:all)  # declared in RSpec.configure
      #
      # This is the reverse of the order in which `before` hooks are run.
      # Similarly, if more than one `after` is declared within any one scope,
      # they are run in reverse order of that in which they are declared.
      def after(*args, &block)
        hooks.register :prepend, :after, *args, &block
      end

      alias_method :prepend_after, :after

      # Adds `block` to the back of the list of `after` blocks in the same
      # scope (`:each`, `:all`, or `:suite`).
      #
      # See #after for scoping semantics.
      def append_after(*args, &block)
        hooks.register :append, :after, *args, &block
      end

      # @api public
      # @overload around(&block)
      # @overload around(scope, &block)
      # @overload around(scope, conditions, &block)
      # @overload around(conditions, &block)
      #
      # @option [Symbol] scope `:each` (defaults to `:each`)
      #   present for syntax parity with `before` and `after`, but `:each` is
      #   the only supported value.
      #
      # @option [Hash] conditions
      #   constrains this hook to examples matching these conditions e.g.
      #   `around(:each, :ui => true) { ... }` will only run with examples or
      #   groups declared with `:ui => true`.
      #
      # @yield [Example] the example to run
      #
      # @note the syntax of `around` is similar to that of `before` and `after`
      #   but the semantics are quite different. `before` and `after` hooks are
      #   run in the context of of the examples with which they are associated,
      #   whereas `around` hooks are actually responsible for running the
      #   examples. Consequently, `around` hooks do not have direct access to
      #   resources that are made available within the examples and their
      #   associated `before` and `after` hooks.
      #
      # @note `:each` is the only supported scope.
      #
      # Declare a block of code, parts of which will be run before and parts
      # after the example. It is your responsibility to run the example:
      #
      #     around(:each) do |ex|
      #       # do some stuff before
      #       ex.run
      #       # do some stuff after
      #     end
      #
      # The yielded example aliases `run` with `call`, which lets you treat it
      # like a `Proc`.  This is especially handy when working with libaries
      # that manage their own setup and teardown using a block or proc syntax,
      # e.g.
      #
      #     around(:each) {|ex| Database.transaction(&ex)}
      #     around(:each) {|ex| FakeFS(&ex)}
      #
      def around(*args, &block)
        hooks.register :prepend, :around, *args, &block
      end

      # @api private
      # Holds the various registered hooks.
      def hooks
        @hooks ||= HookCollections.new(self,
          :around => { :each => AroundHookCollection.new },
          :before => { :each => HookCollection.new, :all => HookCollection.new, :suite => HookCollection.new },
          :after =>  { :each => HookCollection.new, :all => HookCollection.new, :suite => HookCollection.new }
        )
      end

    private

      # @private
      class Hook
        attr_reader :block, :options

        def initialize(block, options)
          @block = block
          @options = options
        end

        def options_apply?(example_or_group)
          example_or_group.all_apply?(options)
        end
      end

      # @private
      class BeforeHook < Hook
        def run(example)
          example.instance_exec(example, &block)
        end

        def display_name
          "before hook"
        end
      end

      # @private
      class AfterHook < Hook
        def run(example)
          example.instance_exec_with_rescue("in an after hook", &block)
        end

        def display_name
          "after hook"
        end
      end

      # @private
      class AfterAllHook < Hook
        def run(example)
          example.instance_exec(example, &block)
        rescue Exception => e
          # TODO: come up with a better solution for this.
          RSpec.configuration.reporter.message <<-EOS

An error occurred in an after(:all) hook.
  #{e.class}: #{e.message}
  occurred at #{e.backtrace.first}

EOS
        end

        def display_name
          "after(:all) hook"
        end
      end

      # @private
      class AroundHook < Hook
        def display_name
          "around hook"
        end
      end

      # @private
      class BaseHookCollection
        Array.public_instance_methods(false).each do |name|
          define_method(name) { |*a, &b| hooks.__send__(name, *a, &b) }
        end

        attr_reader :hooks
        protected   :hooks

        alias append push
        alias prepend unshift

        def initialize(hooks=[])
          @hooks = hooks
        end
      end

      # @private
      class HookCollection < BaseHookCollection
        def for(example_or_group)
          self.class.
            new(hooks.select {|hook| hook.options_apply?(example_or_group)}).
            with(example_or_group)
        end

        def with(example)
          @example = example
          self
        end

        def run
          hooks.each {|h| h.run(@example)}
        end
      end

      # @private
      class AroundHookCollection < BaseHookCollection
        def for(example, initial_procsy=nil)
          self.class.new(hooks.select {|hook| hook.options_apply?(example)}).
            with(example, initial_procsy)
        end

        def with(example, initial_procsy)
          @example = example
          @initial_procsy = initial_procsy
          self
        end

        def run
          hooks.inject(@initial_procsy) do |procsy, around_hook|
            procsy.wrap do
              @example.instance_exec(procsy, &around_hook.block)
            end
          end.call
        end
      end

      # @private
      class GroupHookCollection < BaseHookCollection
        def for(group)
          @group = group
          self
        end

        def run
          hooks.shift.run(@group) until hooks.empty?
        end
      end

      # @private
      class HookCollections
        def initialize(owner, data)
          @owner = owner
          @data  = data
        end

        def [](key)
          @data[key]
        end

        def register_globals(host, globals)
          process(host, globals, :before, :each)
          process(host, globals, :after,  :each)
          process(host, globals, :around, :each)

          process(host, globals, :before, :all)
          process(host, globals, :after,  :all)
        end

        def around_each_hooks_for(example, initial_procsy=nil)
          AroundHookCollection.new(FlatMap.flat_map(@owner.parent_groups) do |a|
            a.hooks[:around][:each]
          end).for(example, initial_procsy)
        end

        def register(prepend_or_append, hook, *args, &block)
          scope, options = scope_and_options_from(*args)
          self[hook][scope].__send__(prepend_or_append, HOOK_TYPES[hook][scope].new(block, options))
        end

        # @private
        #
        # Runs all of the blocks stored with the hook in the context of the
        # example. If no example is provided, just calls the hook directly.
        def run(hook, scope, example_or_group=ExampleGroup.new, initial_procsy=nil)
          return if RSpec.configuration.dry_run?

          find_hook(hook, scope, example_or_group, initial_procsy).run
        end

        SCOPES = [:each, :all, :suite]

        SCOPE_ALIASES = {
          :example => :each,
          :context => :all,
        }

        HOOK_TYPES = {
          :before => Hash.new { BeforeHook },
          :after  => Hash.new { AfterHook  },
          :around => Hash.new { AroundHook }
        }

        HOOK_TYPES[:after][:all] = AfterAllHook

      private

        def process(host, globals, position, scope)
          globals[position][scope].each do |hook|
            next unless scope == :each || hook.options_apply?(host)
            next if host.parent_groups.any? {|a| a.hooks[position][scope].include?(hook)}
            self[position][scope] << hook
          end
        end

        def scope_and_options_from(*args)
          return extract_scope_from(args), Metadata.build_hash_from(args)
        end

        def extract_scope_from(args)
          if known_scope?(args.first)
            normalized_scope_for(args.shift)
          elsif args.any? { |a| a.is_a?(Symbol) }
            error_message = "You must explicitly give a scope (#{SCOPES.join(", ")}) or scope alias (#{SCOPE_ALIASES.keys.join(", ")}) when using symbols as metadata for a hook."
            raise ArgumentError.new error_message
          else
            :each
          end
        end

        # @api private
        def known_scope?(scope)
          SCOPES.include?(scope) || SCOPE_ALIASES.keys.include?(scope)
        end

        # @api private
        def normalized_scope_for(scope)
          SCOPE_ALIASES[scope] || scope
        end

        def find_hook(hook, scope, example_or_group, initial_procsy)
          case [hook, scope]
          when [:before, :all]
            before_all_hooks_for(example_or_group)
          when [:after, :all]
            after_all_hooks_for(example_or_group)
          when [:around, :each]
            around_each_hooks_for(example_or_group, initial_procsy)
          when [:before, :each]
            before_each_hooks_for(example_or_group)
          when [:after, :each]
            after_each_hooks_for(example_or_group)
          when [:before, :suite], [:after, :suite]
            self[hook][:suite].with(example_or_group)
          end
        end

        def before_all_hooks_for(group)
          GroupHookCollection.new(self[:before][:all]).for(group)
        end

        def after_all_hooks_for(group)
          GroupHookCollection.new(self[:after][:all]).for(group)
        end

        def before_each_hooks_for(example)
          HookCollection.new(FlatMap.flat_map(@owner.parent_groups.reverse) do |a|
            a.hooks[:before][:each]
          end).for(example)
        end

        def after_each_hooks_for(example)
          HookCollection.new(FlatMap.flat_map(@owner.parent_groups) do |a|
            a.hooks[:after][:each]
          end).for(example)
        end
      end
    end
  end
end
