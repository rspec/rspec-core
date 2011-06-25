require 'aruba/cucumber'

Before do
  @aruba_timeout_seconds = 5
  ENV['PATH'] = ([File.expand_path('executables')] + @__aruba_original_paths).join(File::PATH_SEPARATOR)
end
