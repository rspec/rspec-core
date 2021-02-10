module RSpec
  module Core
    # Each ExampleGroup class and Example instance owns an instance of
    # Metadata, which is Hash extended to support lazy evaluation of values
    # associated with keys that may or may not be used by any example or group.
    #
    # In addition to metadata that is used internally, this also stores
    # user-supplied metadata, e.g.
    #
    #     RSpec.describe Something, :type => :ui do
    #       it "does something", :slow => true do
    #         # ...
    #       end
    #     end
    #
    # `:type => :ui` is stored in the Metadata owned by the example group, and
    # `:slow => true` is stored in the Metadata owned by the example. These can
    # then be used to select which examples are run using the `--tag` option on
    # the command line, or several methods on `Configuration` used to filter a
    # run (e.g. `filter_run_including`, `filter_run_excluding`, etc).
    #
    # @see Example#metadata
    # @see ExampleGroup.metadata
    # @see FilterManager
    # @see Configuration#filter_run_including
    # @see Configuration#filter_run_excluding
    module Metadata
      # Matches strings either at the beginning of the input or prefixed with a
      # whitespace, containing the current path, either postfixed with the
      # separator, or at the end of the string. Match groups are the character
      # before and the character after the string if any.
      #
      # http://rubular.com/r/fT0gmX6VJX
      # http://rubular.com/r/duOrD4i3wb
      # http://rubular.com/r/sbAMHFrOx1
      def self.relative_path_regex
        @relative_path_regex ||= /(\A|\s)#{File.expand_path('.')}(#{File::SEPARATOR}|\s|\Z)/
      end

      # @api private
      #
      # @param line [String] current code line
      # @return [String] relative path to line
      def self.relative_path(line)
        line = line.sub(relative_path_regex, "\\1.\\2".freeze)
        line = line.sub(/\A([^:]+:\d+)$/, '\\1'.freeze)
        return nil if line == '-e:1'.freeze
        line
      rescue SecurityError
        # :nocov:
        nil
        # :nocov:
      end

      # @private
      # Iteratively walks up from the given metadata through all
      # example group ancestors, yielding each metadata hash along the way.
      def self.ascending(metadata)
        yield metadata
        return unless (group_metadata = metadata.fetch(:example_group) { metadata[:parent_example_group] })

        loop do
          yield group_metadata
          break unless (group_metadata = group_metadata[:parent_example_group])
        end
      end

      # @private
      # Returns an enumerator that iteratively walks up the given metadata through all
      # example group ancestors, yielding each metadata hash along the way.
      def self.ascend(metadata)
        enum_for(:ascending, metadata)
      end

      # @private
      # Used internally to build a hash from an args array.
      # Symbols are converted into hash keys with a value of `true`.
      # This is done to support simple tagging using a symbol, rather
      # than needing to do `:symbol => true`.
      def self.build_hash_from(args)
        hash = args.last.is_a?(Hash) ? args.pop : {}

        hash[args.pop] = true while args.last.is_a?(Symbol)

        hash
      end

      # @private
      def self.deep_hash_dup(object)
        return object.dup if Array === object
        return object unless Hash  === object

        object.inject(object.dup) do |duplicate, (key, value)|
          duplicate[key] = deep_hash_dup(value)
          duplicate
        end
      end

      # @private
      def self.id_from(metadata)
        "#{metadata[:rerun_file_path]}[#{metadata[:scoped_id]}]"
      end

      # @private
      def self.location_tuple_from(metadata)
        [metadata[:absolute_file_path], metadata[:line_number]]
      end

      # @private
      # Used internally to populate metadata hashes with computed keys
      # managed by RSpec.
      class HashPopulator
        attr_reader :metadata, :user_metadata, :description_args, :block

        def initialize(metadata, user_metadata, index_provider, description_args, block)
          @metadata         = metadata
          @user_metadata    = user_metadata
          @index_provider   = index_provider
          @description_args = description_args
          @block            = block
        end

        def populate
          ensure_valid_user_keys

          metadata[:block]            = block
          metadata[:description_args] = description_args
          metadata[:description]      = build_description_from(*metadata[:description_args])
          metadata[:full_description] = full_description
          metadata[:described_class]  = described_class

          populate_location_attributes
          metadata.update(user_metadata)
        end

      private

        def populate_location_attributes
          backtrace = user_metadata.delete(:caller)

          file_path, line_number = if backtrace
                                     file_path_and_line_number_from(backtrace)
                                   elsif block.respond_to?(:source_location)
                                     block.source_location
                                   else
                                     file_path_and_line_number_from(caller)
                                   end

          relative_file_path            = Metadata.relative_path(file_path)
          absolute_file_path            = File.expand_path(relative_file_path)
          metadata[:file_path]          = relative_file_path
          metadata[:line_number]        = line_number.to_i
          metadata[:location]           = "#{relative_file_path}:#{line_number}"
          metadata[:absolute_file_path] = absolute_file_path
          metadata[:rerun_file_path]  ||= relative_file_path
          metadata[:scoped_id]          = build_scoped_id_for(absolute_file_path)
        end

        def file_path_and_line_number_from(backtrace)
          first_caller_from_outside_rspec = backtrace.find { |l| l !~ CallerFilter::LIB_REGEX }
          first_caller_from_outside_rspec ||= backtrace.first
          /(.+?):(\d+)(?:|:\d+)/.match(first_caller_from_outside_rspec).captures
        end

        def description_separator(parent_part, child_part)
          if parent_part.is_a?(Module) && /^(?:#|::|\.)/.match(child_part.to_s)
            ''.freeze
          else
            ' '.freeze
          end
        end

        def build_description_from(parent_description=nil, my_description=nil)
          return parent_description.to_s unless my_description
          return my_description.to_s if parent_description.to_s == ''
          separator = description_separator(parent_description, my_description)
          (parent_description.to_s + separator) << my_description.to_s
        end

        def build_scoped_id_for(file_path)
          index = @index_provider.call(file_path).to_s
          parent_scoped_id = metadata.fetch(:scoped_id) { return index }
          "#{parent_scoped_id}:#{index}"
        end

        def ensure_valid_user_keys
          RESERVED_KEYS.each do |key|
            next unless user_metadata.key?(key)
            raise <<-EOM.gsub(/^\s+\|/, '')
              |#{"*" * 50}
              |:#{key} is not allowed
              |
              |RSpec reserves some hash keys for its own internal use,
              |including :#{key}, which is used on:
              |
              |  #{CallerFilter.first_non_rspec_line}.
              |
              |Here are all of RSpec's reserved hash keys:
              |
              |  #{RESERVED_KEYS.join("\n  ")}
              |#{"*" * 50}
            EOM
          end
        end
      end

      # @private
      class ExampleHash < HashPopulator
        def self.create(group_metadata, user_metadata, index_provider, description, block)
          example_metadata = group_metadata.dup
          example_metadata[:execution_result] = Example::ExecutionResult.new
          example_metadata[:example_group] = group_metadata
          example_metadata[:shared_group_inclusion_backtrace] = SharedExampleGroupInclusionStackFrame.current_backtrace
          example_metadata.delete(:parent_example_group)

          description_args = description.nil? ? [] : [description]
          hash = new(example_metadata, user_metadata, index_provider, description_args, block)
          hash.populate
          hash.metadata
        end

      private

        def described_class
          metadata[:example_group][:described_class]
        end

        def full_description
          build_description_from(
            metadata[:example_group][:full_description],
            metadata[:description]
          )
        end
      end

      # @private
      class ExampleGroupHash < HashPopulator
        def self.create(parent_group_metadata, user_metadata, example_group_index, *args, &block)
          group_metadata =
            if parent_group_metadata
              { **parent_group_metadata, :parent_example_group => parent_group_metadata }
            else
              {}
            end

          hash = new(group_metadata, user_metadata, example_group_index, args, block)
          hash.populate
          hash.metadata
        end

      private

        def described_class
          candidate = metadata[:description_args].first
          return candidate unless NilClass === candidate || String === candidate
          parent_group = metadata[:parent_example_group]
          parent_group && parent_group[:described_class]
        end

        def full_description
          description          = metadata[:description]
          parent_example_group = metadata[:parent_example_group]
          return description unless parent_example_group

          parent_description   = parent_example_group[:full_description]
          separator = description_separator(parent_example_group[:description_args].last,
                                            metadata[:description_args].first)

          parent_description + separator + description
        end
      end

      # @private
      RESERVED_KEYS = [
        :description,
        :description_args,
        :described_class,
        :example_group,
        :parent_example_group,
        :execution_result,
        :last_run_status,
        :file_path,
        :absolute_file_path,
        :rerun_file_path,
        :full_description,
        :line_number,
        :location,
        :scoped_id,
        :block,
        :shared_group_inclusion_backtrace
      ]
    end
  end
end
