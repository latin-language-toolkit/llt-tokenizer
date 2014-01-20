require 'spec_helper'

describe LLT::Token::Punctuation do
  describe "#initialize", :focus do
    it "normalizes escaped xml characters" do
      punct = LLT::Token::Punctuation.new('&amp;')
      punct.to_s.should == '&'
    end
  end

  describe "#as_xml" do
    it "overrides LLT::Core::Containable#as_xml to use xml encodings" do
      punct = LLT::Token::Punctuation.new('&')
      punct.as_xml.should == "&amp;"
    end
  end
end
