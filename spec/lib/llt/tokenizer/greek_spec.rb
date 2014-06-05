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

      describe "with a string that contains an apostrophe" do
        it "returns one token to which the apostrophe is attached" do
          txt = "εὖ δ᾽ ἴστε."
          res = tokenizer.tokenize(txt)
          res.should == %w(εὖ δ᾽ ἴστε .)
          res.should have(4).items
        end

        it "splits two tokens combined by an apostrophe" do
          txt = "εὖ δ᾽ἴστε."
          res = tokenizer.tokenize(txt)
          res.should == %w(εὖ δ᾽ ἴστε .)
          res.should have(4).items
        end
      end
    end

    describe "handles krasis" do
      it "splits a krasis into two words" do
        res = tokenizer.tokenize(krasis)
        res.should have(3).items
        res.should == %w( κ- ἄπειτα . )
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

      context "with options" do
        context "with disabled splitting" do
          it "doesn't split krasis" do
            txt = 'κἄπειτα.'
            opts = { splitting: false }
            tokens = tokenizer.tokenize(txt, opts).map(&:to_s)
            tokens.should == %w{ κἄπειτα . }
          end
        end
      end
    end
  end
end
