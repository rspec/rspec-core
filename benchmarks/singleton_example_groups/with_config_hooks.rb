require_relative 'environment'
tag = ENV['NO_MATCH'] ? :dont_apply_it : :apply_it

RSpec.configure do |c|
  10.times do
    c.before(:context, tag) { }
    c.after(:context, tag) { }
  end
end

require_relative "define_and_run_examples"

__END__

➜  rspec-core git:(master) ✗ time ruby benchmarks/singleton_example_groups/with_config_hooks.rb | grep Finished
Finished in 0.57716 seconds (files took 0.48677 seconds to load)
ruby benchmarks/singleton_example_groups/with_config_hooks.rb  1.04s user 0.07s system 97% cpu 1.138 total

➜  rspec-core git:(more-powerful-include) ✗ time ruby benchmarks/singleton_example_groups/with_config_hooks.rb | grep Finished
Finished in 2.89 seconds (files took 0.43151 seconds to load)
ruby benchmarks/singleton_example_groups/with_config_hooks.rb  3.31s user 0.08s system 99% cpu 3.397 total

➜  rspec-core git:(more-powerful-include) ✗ time NO_MATCH=1 ruby benchmarks/singleton_example_groups/with_config_hooks.rb | grep Finished
Finished in 1.4 seconds (files took 0.43545 seconds to load)
NO_MATCH=1 ruby benchmarks/singleton_example_groups/with_config_hooks.rb  1.84s user 0.08s system 99% cpu 1.921 total
