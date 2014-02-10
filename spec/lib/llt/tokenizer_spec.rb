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
        txt = "<Marcus> (et Claudius) †amici† [sunt]."
        tokens = tokenizer.tokenize(txt)
        tokens.should have(14).items
        tokens.map(&:to_s).should == %w{ < Marcus > ( et Claudius ) † amici † [ sunt ] . }
      end

      it "handles escaped xml characters" do
        txt = "&amp; &quot; &apos; &gt; &lt; ;"
        tokens = tokenizer.tokenize(txt)
        tokens.should have(6).items
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

        context "with quantified text" do
          it "handles unshifted" do
            txt = 'M. Cicero pecūniam gaudĭămquĕ incolīs dabit.'
            tokens = tokenizer.tokenize(txt, shifting: false).map(&:to_s)
            tokens.should == %w{ M. Cicero pecūniam gaudĭăm -quĕ incolīs dabit . }
          end

          it "handles shifted" do
            txt = 'M. Cicero pecūniam gaudĭămquĕ incolīs dabit.'
            tokens = tokenizer.tokenize(txt, shifting: true).map(&:to_s)
            tokens.should == %w{ M. Cicero pecūniam -quĕ gaudĭăm incolīs dabit . }
          end

          it "handles double-shifted" do
            txt = 'M. Cicero pecūniam Italia in eoquĕ dabit.'
            tokens = tokenizer.tokenize(txt, shifting: true).map(&:to_s)
            tokens.should == %w{ M. Cicero pecūniam Italia -quĕ in eo dabit . }
          end

          it "handles merging" do
            txt = 'Quăm diu M. Cicero pecūniam Italia dabit.'
            tokens = tokenizer.tokenize(txt, shifting: true).map(&:to_s)
            tokens.should == %w{ Quămdiu M. Cicero pecūniam Italia dabit . }
          end
        end

        context "with more exotic punctuation" do
          it "handles -- as single Punctuation token" do
            txt = 'Arma -- virum -- cano.'
            tokens = tokenizer.tokenize(txt)
            tokens.should have(6).items
          end

          it "handles ?! as two separate tokens" do
            txt = 'Arma cano!?'
            tokens = tokenizer.tokenize(txt)
            tokens.should have(4).items
          end

          context "handles direct speech delimiters" do
            it "'" do
              txt = "'Arma', inquit 'cano'."
              tokens = tokenizer.tokenize(txt)
              tokens.should have(9).items
            end

            it '"' do
              txt = '"Arma" inquit "cano".'
              tokens = tokenizer.tokenize(txt)
              tokens.should have(8).items
            end

            it '”' do
              txt = '”Arma” inquit ”cano”.'
              tokens = tokenizer.tokenize(txt)
              tokens.should have(8).items
            end
          end
        end
      end
    end

    describe "#find_abbreviations_and_join_strings" do
      describe "should bring back abbreviation dots and apostrophes" do
        it "with names" do
          tokenizer.setup("", {}, %w{ Atque Sex . et M . Cicero . })
          tokenizer.find_abbreviations_and_join_strings
          tokenizer.preliminary.should == %w{ Atque Sex. et M. Cicero . }
        end

        it "with roman date" do
          tokenizer.setup("", {}, %w{ a . d . V Kal . Apr . })
          tokenizer.find_abbreviations_and_join_strings
          tokenizer.preliminary.should == %w{ a. d. V Kal. Apr. }
        end

        it "with apostrophe" do
          tokenizer.setup("", {}, %w{ ' Apostrophi ' sunt : po ' min ' vin ' tun' scin ' potin ' satin ' })
          tokenizer.find_abbreviations_and_join_strings
          tokenizer.preliminary.should == %w{ ' Apostrophi ' sunt : po' min' vin' tun' scin' potin' satin' }
        end
      end
    end

    describe "#split_enklitika_and_change_their_position" do
      def enklitika_test(example)
        tokenizer.setup("", {}, example.split)
        tokenizer.split_enklitika_and_change_their_position
        tokenizer.preliminary
      end

      context "when confronted with -que" do
        # even if should_not be splitted would be more expressive,
        # use only positive expectation as it gives more detailed feedback
        examples = {
          "laetusque" => "-que laetus",
          "in eoque"  => "-que in eo",
          "In eoque"  => "-que In eo",
          "ad eamque" => "-que ad eam",
          "ob easque" => "-que ob eas",
          "neque"     => "-que ne",
          "nec"       => "-c ne",
          "Atque"     => "Atque",
          "atque"     => "atque",
          "cuiusque"  => "cuiusque",
          "denique"   => "denique",
          "itaque"    => "itaque",
          "plerumque" => "plerumque",
          "plerosque" => "plerosque",
          "plerique"  => "plerique",
          "plerarumque"  => "plerarumque",
          "quaque"    => "quaque",
          "quemque"   => "quemque",
          "undique"   => "undique",
          "uterque"   => "uterque",
          "utriusque" => "utriusque",
          "utcumque"  => "utcumque",
          "usque"     => "usque",
          "bonus laetusque et latus altusque" => "bonus -que laetus et latus -que altus",
          "quantumcumque" => "quantumcumque",
          "quantulacumque" => "quantulacumque"
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
          "iactatione"   => "iactatione",
          "Platone"      => "Platone",
          "libidine"     => "libidine",
          "Solone"       => "Solone",
          "homine"       => "homine",
          "flumine"      => "flumine",
          "fine"         => "fine",
          "iuvene"       => "iuvene",

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

          # nouns in vocative in o declension
          "Pauline"   => "Pauline",
          "domine"    => "domine",

          # adjective in vocative in a/o declension
          "bone"      => "bone",
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
          'vive'     => 'vive',
          'move'     => 'move',
          'neve'     => 'neve',
          'cive'     => 'cive',
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
        tokenizer.preliminary
      end

      describe("quam diu")    { it { should be_transformed_to "quamdiu" } }
      describe("Quam diu")    { it { should be_transformed_to "Quamdiu" } }
      describe("erat diu")    { it { should_not be_transformed_to "eratdiu" } }
      describe("non nullis")  { it { should be_transformed_to "nonnullis" } }
    end

    describe "#create_tokens" do
      def sentence_element_test(example)
        tokenizer.setup("", {}, example.split)
        tokenizer.create_tokens.first
      end

      examples = {
        "Word"     => %w{ ita Marcus quoque -que po' },
        "Filler"   => %w{ M. Sex. App. Ap. Tib. Ti. C. a. d. Kal. Ian. }, #I XI MMC }
        "XmlTag"   => %w{ <grc> </grc> },
        "Punctuation" => %w{ , . ! ? † ( ) [ ] ... -- ” " ' & < > &amp; &lt; &gt; &apos; &quot; }
      }

      examples.each do |klass, elements|
        elements.each do |e|
          it "#{e} is a LLT::#{klass}" do
            sentence_element_test(e).should be_an_instance_of LLT::Token.const_get(klass)
          end
        end
      end

      it "handles complex xml tags with attributes as well" do
        tokenizer.setup('', {}, ['<foreign lang="grc">'])
        tokenizer.create_tokens.first.should be_an_instance_of LLT::Token::XmlTag
      end
    end

    it "attaches id's to tokens" do
      txt = 'Cano.'
      tokens = tokenizer.tokenize(txt)
      tokens.map(&:id).should == [1, 2]
    end

    it "id's can be disabled" do
      txt = 'Cano.'
      tokens = tokenizer.tokenize(txt, indexing: false)
      tokens.map(&:id).should == [nil, nil]
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

      context "with disabled merging" do
        it "doesn't merge things like quam diu" do
          txt = 'quam diu cano?'
          opts = { merging: false }
          tokens = tokenizer.tokenize(txt, opts).map(&:to_s)
          tokens.should == %w{ quam diu cano ? }
        end
      end

      context "with disabled splitting" do
        it "doesn't split enclitics" do
          txt = 'arma virumque cano.'
          opts = { splitting: false }
          tokens = tokenizer.tokenize(txt, opts).map(&:to_s)
          tokens.should == %w{ arma virumque cano . }
        end
      end

      context "with xml handling enabled" do
        let(:xml_tokenizer) { LLT::Tokenizer.new(db: stub_db, xml: true) }

        it "doesn't break when xml is embedded" do
          txt = '<grc>text text</grc>'
          tokens = xml_tokenizer.tokenize(txt)
          tokens.should have(4).items
        end

        it "doesn't count plain xml tags" do
          txt = '<grc>text text</grc>'
          tokens = xml_tokenizer.tokenize(txt)
          tokens.map(&:id).should == [nil, 1, 2, nil]
        end

        it "doesn't count xml tags when they come with attributes" do
          txt = '<foreign lang="lat">Graeca</foreign> lingua est.'
          tokens = xml_tokenizer.tokenize(txt).map(&:to_s)
          res = ['<foreign lang="lat">', 'Graeca', '</foreign>', 'lingua', 'est', '.']
          tokens.should == res
        end

        it "handles nested xml as well" do
          txt = '<l n="70"><foreign lang="lat">Graeca lingua est.</foreign></l>'
          tokens = xml_tokenizer.tokenize(txt).map(&:to_s)
          res = ['<l n="70">', '<foreign lang="lat">', 'Graeca', 'lingua', 'est', '.', '</foreign>', '</l>']
          tokens.should == res
        end

        it "handles text with broken off xml tags (the rest will e.g. be in another sentence)" do
          txt = "<lg org=\"uniform\" sample=\"complete\"><l>quem vocet divum populus ruentis</l><l>imperi rebus?"
          tokens = xml_tokenizer.tokenize(txt)
          tokens.should have(12).items
        end

        it "doesn't fall with spaces inside of xml attributes" do
          txt = '<test>veni vidi <bad att="a a a">vici</bad></test>'
          tokens = xml_tokenizer.tokenize(txt)
          tokens.should have(7).items
        end

        it "expects all text chevrons to be escaped, otherwise they are xml tags!" do
          txt = '<test>&lt;veni&gt;</test>'
          tokens = xml_tokenizer.tokenize(txt)
          tokens.should have(5).item
        end
      end
    end
  end

  context "with options on instance creation" do
    it "a new instance can receive options, which it will use as its defaults" do
      custom_tok = LLT::Tokenizer.new(db: stub_db,
                                      shifting: false,
                                      enclitics_marker: '')
      tokens = custom_tok.tokenize('Arma virumque cano.').map(&:to_s)
      tokens.should == %w{ Arma virum que cano . }
    end
  end
end
