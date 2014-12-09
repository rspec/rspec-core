require_relative 'environment'
require_relative "define_and_run_examples"

__END__

➜  rspec-core git:(master) ✗ time ruby benchmarks/singleton_example_groups/with_no_config_hooks_or_inclusions.rb | grep Finished
Finished in 0.62426 seconds (files took 0.42048 seconds to load)
ruby benchmarks/singleton_example_groups/with_no_config_hooks_or_inclusions.r  1.03s user 0.08s system 98% cpu 1.123 total

➜  rspec-core git:(more-powerful-include) ✗ time ruby benchmarks/singleton_example_groups/with_no_config_hooks_or_inclusions.rb | grep Finished
Finished in 0.89069 seconds (files took 0.42335 seconds to load)
ruby benchmarks/singleton_example_groups/with_no_config_hooks_or_inclusions.r  1.32s user 0.08s system 99% cpu 1.406 total
