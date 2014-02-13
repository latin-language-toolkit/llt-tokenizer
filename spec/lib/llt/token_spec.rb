require 'spec_helper'

describe LLT::Token do
  let(:token) { LLT::Token }

  describe "#==" do
    it "equals when two takes have the same string value" do
      t1 = token.new('bene')
      t2 = token.new('bene')
      t1.should == t2
    end

    it "doesn't equal when the strings are different" do
      t1 = token.new('bene')
      t2 = token.new('male')
      t1.should_not == t2
    end

    it "is case insensitive" do
      t1 = token.new('bene')
      t2 = token.new('Bene')
      t1.should == t2
    end
  end
end
