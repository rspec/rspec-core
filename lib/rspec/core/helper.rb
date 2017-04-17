module RSpec
  module Core
    # Extend helper with this module and specify cases when you want this filter
    # to be available in.
    #
    #     module SignInHelper
    #       extend RSpec::Core::Helper
    #       register_helper :include, type: :controller
    #       # ...
    #     end
    module Helper
      class << self
        def register(mod, *actions, **filter)
          @modules ||= Hash.new { |h, k| h[k] = [] }
          @modules[mod] << [actions, filter]
        end

        def apply(config)
          @modules.each do |mod, rules|
            rules.each do |(actions, filter)|
              actions.each do |action|
                config.public_send action, mod, filter
              end
            end
            mod.applied(config)
          end
        end
      end

      def register_helper(*actions, **filter)
        Helper.register self, *actions, filter
      end

      def applied(_config)
      end
    end
  end
end
