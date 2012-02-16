require 'spec_helper'

describe "#let" do
  let(:counter, :another_counter) do
    Class.new do
      def initialize
        @count = 0
      end
      def count
        @count += 1
      end
    end.new
  end

  let(:nil_value) do
    @nil_value_count += 1
    nil
  end

  it "generates an instance method" do
    counter.count.should eq(1)
  end

  it "caches the value" do
    counter.count.should eq(1)
    counter.count.should eq(2)
  end

  it "caches a nil value" do
    @nil_value_count = 0
    nil_value
    nil_value

    @nil_value_count.should eq(1)
  end

  it "caches multiple arguments separately" do
    counter.should_not eq(another_counter)
  end
end

describe "#let!" do
  let!(:creator, :another_creator) do
    Class.new do
      @count = 0
      def self.count
        @count += 1
      end
    end
  end

  it "evaluates the value non-lazily" do
    lambda { creator.count }.should_not raise_error
  end

  it "does not interfere between tests" do
    creator.count.should eq(1)
  end

  it "caches multiple arguments separately" do
    creator.should_not eq(another_creator)
  end

end
