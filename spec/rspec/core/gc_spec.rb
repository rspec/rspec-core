require 'spec_helper'

describe RSpec::Core do

  describe "#configuration" do
    it "allows us to disable GC" do
      GC.start # Encourage GC before disabling in case we're near trigger
               # threshold -- don't want calling configure to up the GC count.
      RSpec.configuration.gc_every_n_examples = 1 # This should call GC.disable.
      cycles_before = GC.count
      GC.start # This is a no-op if GC has been disabled.
      cycles_after = GC.count
      cycles_after.should == cycles_before

      # TODO: Wipe the configuration, re-enable GC, etc.
    end
  end

end
