require_relative 'environment'

tag = ENV['NO_MATCH'] ? :dont_apply_it : :apply_it

1.upto(10) do |i|
  RSpec.shared_context "context #{i}", tag do
  end
end

require_relative "define_and_run_examples"

__END__

➜  rspec-core git:(master) ✗ time ruby benchmarks/singleton_example_groups/with_shared_context_inclusions.rb | grep Finished
Finished in 0.61633 seconds (files took 0.46043 seconds to load)
ruby benchmarks/singleton_example_groups/with_shared_context_inclusions.rb  1.07s user 0.07s system 96% cpu 1.181 total

➜  rspec-core git:(more-powerful-include) ✗ time ruby benchmarks/singleton_example_groups/with_shared_context_inclusions.rb | grep Finished
Finished in 7.4 seconds (files took 0.44129 seconds to load)
ruby benchmarks/singleton_example_groups/with_shared_context_inclusions.rb  7.79s user 0.14s system 99% cpu 7.964 total

➜  rspec-core git:(more-powerful-include) ✗ time NO_MATCH=1 ruby benchmarks/singleton_example_groups/with_shared_context_inclusions.rb | grep Finished
Finished in 1.15 seconds (files took 0.47696 seconds to load)
NO_MATCH=1 ruby   1.63s user 0.08s system 99% cpu 1.716 total
