module RSpec
  module Core
    module Metadata
      def self.relative_path(line)
        line = line.sub(File.expand_path("."), ".")
        line = line.sub(/\A([^:]+:\d+)$/, '\\1')
        return nil if line == '-e:1'
        line
      rescue SecurityError
        nil
      end

      # @private
      # Used internally to build a hash from an args array.
      # Symbols are converted into hash keys with a value of `true`.
      # This is done to support simple tagging using a symbol, rather
      # than needing to do `:symbol => true`.
      def self.build_hash_from(args)
        hash = args.last.is_a?(Hash) ? args.pop : {}

        while args.last.is_a?(Symbol)
          hash[args.pop] = true
        end

        hash
      end
    end

    class MetadataBase
      def initialize(user_metadata)
        @file_path   = nil
        @line_number = nil
        @user_metadata = user_metadata
        @caller      = user_metadata.delete(:caller) || ::Kernel.caller
      end

      attr_reader :description_args, :caller, :user_metadata

      def description
        @description ||= build_description_from(*description_args)
      end
      attr_writer :description

      def file_path
        parse_file_path_and_line_number unless @file_path
        @file_path
      end

      def line_number
        parse_file_path_and_line_number unless @line_number
        @line_number
      end

      def location
        @location ||= "#{file_path}:#{line_number}"
      end

      def any_apply?(filters)
        filters.any? {|k,v| filter_applies?(k,v)}
      end

      def all_apply?(filters)
        filters.all? {|k,v| filter_applies?(k,v)}
      end

      def inspect
        # TODO: spec this
        "#<#{self.class.name} #{full_description.inspect}>"
      end

      def filter_applies?(key, value, rspec_metadata=self)
        if rspec_metadata.respond_to?(:user_metadata)
          metadata = rspec_metadata.user_metadata
        else
          metadata = rspec_metadata
        end

        if Array === metadata[key] && !(Proc === value)
          return rspec_metadata.filter_applies_to_any_value?(key, value)
        elsif key == :line_numbers
          return rspec_metadata.line_number_filter_applies?(value)
        elsif key == :locations
          return rspec_metadata.location_filter_applies?(value)
        elsif Hash === value
          return rspec_metadata.filters_apply?(key, value)
        end

        # TODO: spec this line
        return false unless metadata.has_key?(key)

        case value
          when Regexp
            metadata[key] =~ value
          when Proc
            case value.arity
            when 0 then value.call
            when 2 then value.call(metadata[key], metadata)
            else value.call(metadata[key])
            end
          else
            metadata[key].to_s == value.to_s
        end
      end

    protected

      def filters_apply?(key, value)
        value.all? {|k, v| filter_applies?(k, v, user_metadata[key])}
      end

      def filter_applies_to_any_value?(key, value)
        user_metadata[key].any? {|v| filter_applies?(key, v, {key => value})}
      end

      def line_number_filter_applies?(line_numbers)
        preceding_declaration_lines = line_numbers.map {|n| RSpec.world.preceding_declaration_line(n)}
        !(relevant_line_numbers & preceding_declaration_lines).empty?
      end

      # @private
      def location_filter_applies?(locations)
        # it ignores location filters for other files
        line_number = example_group_declaration_line(locations)
        line_number ? line_number_filter_applies?(line_number) : true
      end

      def example_group_declaration_line(locations)
        locations[File.expand_path(file_path)] if parent_group_rspec_meta
      end

      # TODO - make this a method on metadata - the problem is
      # metadata[:example_group] is not always a kind of GroupMetadataHash.
      def relevant_line_numbers
        numbers_from_parents = if parent_group_rspec_meta
                                 parent_group_rspec_meta.relevant_line_numbers
                               else
                                 []
                               end

        [line_number] + numbers_from_parents
      end

    private

      def parse_file_path_and_line_number
        first_caller_from_outside_rspec =~ /(.+?):(\d+)(|:\d+)/
        @file_path = Metadata.relative_path($1)
        @line_number = $2.to_i
      end

      def first_caller_from_outside_rspec
        caller.detect {|l| l !~ /\/lib\/rspec\/core/}
      end

      def method_description_after_module?(parent_part, child_part)
        return false unless parent_part.is_a?(Module)
        child_part =~ /^(#|::|\.)/
      end

      def build_description_from(first_part = '', *parts)
        description, _ = parts.inject([first_part.to_s, first_part]) do |(desc, last_part), this_part|
          this_part = this_part.to_s
          this_part = (' ' + this_part) unless method_description_after_module?(last_part, this_part)
          [(desc + this_part), this_part]
        end

        description
      end
    end

    class GroupMetadata < MetadataBase
      def self.metadata_hash_from(superclass_metadata, *args)
        user_metadata = args.last.is_a?(Hash) ? args.pop : {}

        # TODO: spec inheritance
        if superclass_metadata
          user_metadata = superclass_metadata.merge(user_metadata)
        end

        # TODO: spec the inclusion of user metadata
        group_metadata = new(superclass_metadata, user_metadata, *args)

        user_metadata[:rspec] = group_metadata
        user_metadata
      end

      attr_reader :parent_group_metadata, :parent_group_rspec_meta

      def initialize(parent_group_metadata, user_metadata, *args)
        @parent_group_metadata = parent_group_metadata

        if parent_group_metadata
          @parent_group_rspec_meta = parent_group_metadata[:rspec]
        end

        @description_args = args
        super(user_metadata)
      end

      def metadata_for_example(example, description, metadata)
        # TODO: spec inheritance
        metadata = user_metadata.merge(metadata)
        metadata.merge(:rspec => ExampleMetadata.new(self, example, description, metadata))
      end

      def full_description
        build_description_from(*FlatMap.flat_map(container_stack.reverse) { |m| m.description_args })
      end

      def described_class
        @described_class ||= inferred_described_class
      end
      alias describes described_class
      attr_writer :described_class

    private

      def container_stack
        @container_stack ||= begin
          groups = [group = self]
          while (parent = group.parent_group_rspec_meta)
            groups << (group = parent)
          end
          groups
        end
      end

      def inferred_described_class
        container_stack.each do |g|
          return g.described_class if !g.equal?(self) && g.described_class
          candidate = g.description_args.first
          return candidate unless String === candidate || Symbol === candidate
        end

        nil
      end
    end

    class ExampleMetadata < MetadataBase
      def initialize(example_group_rspec_meta, example, description, user_metadata)
        @example_group_rspec_meta = example_group_rspec_meta
        @description_args = [description].compact
        @example = example
        super(user_metadata)
      end

      # TODO: come up with a combined name for both.
      attr_reader :example_group_rspec_meta
      alias parent_group_rspec_meta example_group_rspec_meta

      attr_accessor :skip

      def execution_result
        @execution_result ||= ExecutionResult.new
      end

      def pending

      end

      def example_group
        @example.example_group
      end

      def full_description
        build_description_from \
          example_group_rspec_meta.full_description,
          *description_args
      end
    end

    class ExecutionResult
      attr_accessor :status, :finished_at, :run_time, :started_at,
                    :exception, :pending_message, :pending_exception,
                    :pending_fixed

      def update(results)
        results.each do |key, value|
          __send__(:"#{key}=", value)
        end
      end

      def [](key)
        __send__(key)
      end
    end
  end
end

