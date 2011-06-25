require 'aruba/cucumber'

Before do
  @aruba_timeout_seconds = 5
  ENV['PATH'] = "#{File.expand_path(File.dirname(__FILE__) + '/../../executables')}#{File::PATH_SEPARATOR}#{ENV['PATH']}"
end
