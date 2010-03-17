require 'spec_helper'

module Bug7611
  describe "A Partial Mock" do
    class Foo
    end

    class Bar < Foo
    end
    it "should respect subclasses" do
      Foo.stub(:new).and_return(Object.new)
    end

    it "should" do
      Bar.new.class.should == Bar
    end 
  end
end
