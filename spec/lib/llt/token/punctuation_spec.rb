require 'spec_helper'

describe LLT::Token::Punctuation do
  describe "#as_xml" do
    it "overrides LLT::Core::Containable#as_xml to use xml encodings" do
      punct = LLT::Token::Punctuation.new('&')
      punct.as_xml.should == "&amp;"
    end
  end
end
