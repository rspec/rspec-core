require_relative 'environment'

tag = ENV['NO_MATCH'] ? :dont_apply_it : :apply_it

RSpec.configure do |c|
  1.upto(10) do
    c.include Module.new, tag
  end
end

require_relative "define_and_run_examples"

__END__

➜  rspec-core git:(master) ✗ time ruby benchmarks/singleton_example_groups/with_module_inclusions.rb | grep Finished
Finished in 0.58963 seconds (files took 0.43602 seconds to load)
ruby benchmarks/singleton_example_groups/with_module_inclusions.rb  1.02s user 0.07s system 99% cpu 1.101 total

➜  rspec-core git:(more-powerful-include) ✗ time ruby benchmarks/singleton_example_groups/with_module_inclusions.rb | grep Finished
Finished in 1.37 seconds (files took 0.46071 seconds to load)
ruby benchmarks/singleton_example_groups/with_module_inclusions.rb  1.83s user 0.08s system 99% cpu 1.925 total

➜  rspec-core git:(more-powerful-include) ✗ time NO_MATCH=1 ruby benchmarks/singleton_example_groups/with_module_inclusions.rb | grep Finished
Finished in 1.13 seconds (files took 0.43054 seconds to load)
NO_MATCH=1 ruby benchmarks/singleton_example_groups/with_module_inclusions.rb  1.57s user 0.08s system 99% cpu 1.655 total
