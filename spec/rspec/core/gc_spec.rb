require 'spec_helper'

describe RSpec::Core do

  describe "#configuration" do
    if(GC.respond_to?(:count))
      it "allows us to use normal GC behavior" do
        RSpec.configuration.gc_every_n_examples = 0 # This should call GC.enable.

        cycles_before = GC.count
        GC.start # This is a no-op if GC has been disabled.
        cycles_after = GC.count

        cycles_after.should_not == cycles_before
      end

      it "allows us to disable GC" do
        RSpec.configuration.gc_every_n_examples = 1 # This should call GC.disable.

        cycles_before = GC.count
        GC.start # This is a no-op if GC has been disabled.
        cycles_after = GC.count

        cycles_after.should == cycles_before
      end

      before do
        # Be courteous to other test groups / global suite configuration which
        # might want to set this option...
        @saved_gc_config = RSpec.configuration.gc_every_n_examples
      end

      after do
        RSpec.configuration.gc_every_n_examples = @saved_gc_config
      end
    else
      it "doesn't do squat because our Ruby doesn't have GC.count" do
        pending "Skipping GC test on Ruby that doesn't support GC.count."
      end
    end
  end

end
