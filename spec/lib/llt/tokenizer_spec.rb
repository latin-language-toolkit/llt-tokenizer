require 'spec_helper'

describe LLT::Tokenizer do
  before(:all) { LLT::DbHandler::Stub.setup }

  let(:stub_db) { LLT::DbHandler::Stub.new }
  let(:tokenizer) { LLT::Tokenizer.new(db: stub_db) }
  let(:txt) { "Atque Sex. et M. Cicero." }
  let(:long_text) { "C. Caesar Antoniusque ratione superavit." }
  let(:date) { "a. d. V Kal. Apr." }

  context "with default options" do
    describe "#tokenize" do
      it "tokenizes a string" do
        # tokens are C. Caesar -que Antonius ratione superavit .
        # require 'pry'; binding.pry
        tokenizer.tokenize(long_text).should have(7).items
      end

      it "handles all kinds of parens as well as cruces" do
        txt = "Marcus (et Claudius) †amici† [sunt]."
        tokens = tokenizer.tokenize(txt)
        tokens.should have(12).items
        tokens.map(&:to_s).should == %w{ Marcus ( et Claudius ) † amici † [ sunt ] . }
      end

      describe "takes an optional keyword argument add_to" do
        class SentenceDummy
          attr_reader :tokens
          def initialize; @tokens = []; end
          def <<(tokens); @tokens += tokens; end
        end

        it "adds the result to the given object if #<< is implemented" do
          sentence = SentenceDummy.new
          t = tokenizer.tokenize("est.", add_to: sentence)
          sentence.tokens.should == t
        end

        it "does nothing to the given object when #<< it does not respond to" do
          object = double(respond_to?: false)
          object.should_not receive(:<<)
          tokenizer.tokenize("est.", add_to: object)
        end

        it "returns an empty if the argument is an empty string" do
          tokenizer.tokenize("").should == []
        end

        it "raises an error if argument is not a string" do
          expect { tokenizer.tokenize([]) }.to raise_error ArgumentError
        end
      end
    end

    # the following specs could be considered private

    describe "#create_array_elements" do
      it "should split between punctuation and spaces" do
        tokenizer.setup(txt)
        tokenizer.create_array_elements.should == %w{ Atque Sex . et M . Cicero . }
      end

      describe "when confronted with a roman date expression" do
        it "should split between punctuation and spaces" do
          tokenizer.setup(date)
          tokenizer.create_array_elements.should == %w{ a . d . V Kal . Apr . }
        end
      end
    end

    describe "#find_abbreviations_and_join_strings" do
      describe "should bring back abbreviation dots" do
        it "with names" do
          tokenizer.setup("", {}, %w{ Atque Sex . et M . Cicero . })
          tokenizer.find_abbreviations_and_join_strings.should == %w{ Atque Sex. et M. Cicero . }
        end

        it "with roman date" do
          tokenizer.setup("", {}, %w{ a . d . V Kal . Apr . })
          tokenizer.find_abbreviations_and_join_strings.should == %w{ a. d. V Kal. Apr. }
        end
      end
    end

    describe "#split_enklitika_and_change_their_position" do
      def enklitika_test(example)
        tokenizer.setup("", {}, example.split)
        tokenizer.split_enklitika_and_change_their_position
      end

      context "when confronted with -que" do
        # even if should_not be splitted would be more expressive,
        # use only positive expectation as it gives more detailed feedback
        examples = {
          "laetusque" => "-que laetus",
          "in eoque"  => "-que in eo",
          "ad eamque" => "-que ad eam",
          "ob easque" => "-que ob eas",
          "Atque"     => "Atque",
          "atque"     => "atque",
          "cuiusque"  => "cuiusque",
          "denique"   => "denique",
          "itaque"    => "itaque",
          "neque"     => "neque",
          "plerumque" => "plerumque",
          "quaque"    => "quaque",
          "quemque"   => "quemque",
          "undique"   => "undique",
          "uterque"   => "uterque",
          "utriusque" => "utriusque",
          "bonus laetusque et latus altusque" => "bonus -que laetus et latus -que altus",
        }

        examples.each do |example, expected|
          it "transforms #{example} to #{expected}" do
            enklitika_test(example).should be_transformed_to expected
          end
        end
      end

      context "when confronted with -ne" do
        examples = {
          "honestumne" => "-ne honestum",
          "omniane"    => "-ne omnia",

          # frequent patterns in third declension nouns
          "ratione"      => "ratione",
          "magnitudine"  => "magnitudine",
          "Platone"      => "Platone",
          "libidine"     => "libidine",
          "Solone"       => "Solone",
          "homine"       => "homine",
          "flumine"      => "flumine",

          # frequent patterns in third declension adjective
          "commune"    => "commune",
          "Commune"    => "Commune",

          # filtered by restrictor array
          "omne"       => "omne",
          "sine"       => "sine",
          "bene"       => "bene",
          "paene"      => "paene",

          # ne itself should be contained
          "ne"         => "ne",
        }

        examples.each do |example, expected|
          it "transforms #{example} to #{expected}" do
            enklitika_test(example).should be_transformed_to expected
          end
        end
      end

      context "when confronted with -ve" do
        examples = {
          'sive'     => 'sive',
          'pluresve' => '-ve plures',
          'aestive'  => 'aestive',
          'serve'    => 'serve',
          'suave'    => 'suave',
        }

        examples.each do |example, expected|
          it "transforms #{example} to #{expected}" do
            enklitika_test(example).should be_transformed_to expected
          end
        end
      end
    end

    describe "#merge_what_needs_merging" do
      subject do
        tokenizer.setup("", {}, self.class.description.split)
        tokenizer.merge_what_needs_merging
      end

      describe("quam diu")    { it { should be_transformed_to "quamdiu" } }
      describe("erat diu")    { it { should_not be_transformed_to "eratdiu" } }
    end

    describe "#create_tokens" do
      def sentence_element_test(example)
        tokenizer.setup("", {}, example.split)
        tokenizer.create_tokens.first
      end

      examples = { "Word"     => %w{ ita Marcus quoque },
                   "Filler"   => %w{ M. Sex. App. Ap. Tib. Ti. C. a. d. Kal. Ian. }, #I XI MMC }
                   "Punctuation" => %w{ , . ! ? † ( ) [ ] } }

      examples.each do |klass, elements|
        elements.each do |e|
          it "#{e} is a LLT::#{klass}" do
            sentence_element_test(e).should be_an_instance_of LLT::Token.const_get(klass)
          end
        end
      end
    end
  end

  context "with options" do
    describe "#tokenize" do
      context "with custom enclitics marker" do
        it "uses the given marker" do
          txt = 'Arma virumque cano.'
          opts = { enclitics_marker: '--' }
          tokens = tokenizer.tokenize(txt, opts)
          tokens.map(&:to_s).should == %w{ Arma --que virum cano . }
        end
      end

      context "with disabled shifting" do
        it "doesn't shift" do
          txt = 'Arma virumque in carmina et in eoque cano.'
          opts = { shifting: false }
          tokens = tokenizer.tokenize(txt, opts).map(&:to_s)
          tokens.should == %w{ Arma virum -que in carmina et in eo -que cano . }
        end

        it "doesn't shift (complex)" do
          txt = 'ratione arma virumque cano.'
          opts = { shifting: false }
          tokens = tokenizer.tokenize(txt, opts).map(&:to_s)
          tokens.should == %w{ ratione arma virum -que cano . }
        end
      end
    end
  end

  context "with options on instance creation" do
    it "a new instance can receive options, which it will use as it's defaults" do
      custom_tok = LLT::Tokenizer.new(db: stub_db,
                                      shifting: false,
                                      enclitics_marker: '')
      tokens = custom_tok.tokenize('Arma virumque cano.').map(&:to_s)
      tokens.should == %w{ Arma virum que cano . }
    end
  end
end
