module RSpec # :nodoc:
  module Mocks # :nodoc:
    module Version # :nodoc:
      STRING = File.readlines(File.expand_path('../../../../VERSION', __FILE__)).first
    end
  end
end
