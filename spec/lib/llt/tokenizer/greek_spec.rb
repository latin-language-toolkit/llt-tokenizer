require 'spec_helper'

describe LLT::Tokenizer::Greek do
  let(:tokenizer) { LLT::Tokenizer.new }
  let(:greek_txt) { "καὶ διὰ τῆς περὶ τὴν ἀρχαιολογίαν συγγραφῆς."}
  let(:krasis) { "κἄπειτα." }
  let(:double_krasis) { "κἄπειτα τῆς περὶ τὴν ἀρχαιολογίαν κἄπειτα." }
  let(:diphtong) { "τοὔνομα." }

  context "with greek tokens" do
    describe "#tokenize" do
      it "tokenizes a string" do
        res = tokenizer.tokenize(greek_txt)
        res.should == %w(καὶ διὰ τῆς περὶ τὴν ἀρχαιολογίαν συγγραφῆς .)
        res.should have(8).items
      end
    end

    describe "handles krasis" do
      it "splits a krasis into two words" do
        tokenizer.tokenize(krasis).should have(3).items
      end

      it "handles a dipthong krasis" do
        res = tokenizer.tokenize(diphtong)
        res.should have(3).items
      end

      it "splits two kraseis in a sentence" do
        res = tokenizer.tokenize(double_krasis)
        res.should have(9).items
        res[2].should == "τῆς"
        res[8].should == "."
      end
    end
  end

end
