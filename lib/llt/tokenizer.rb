require 'llt/core'
require 'llt/db_handler/prometheus'

module LLT
  class Tokenizer
    include Core::Serviceable
    include Constants::Abbreviations

    uses_db { DbHandler::Prometheus.new }


    def self.tokenize(input)
      new(input).tokenize
    end

    def tokenize(text, add_to: nil)
      raise ArgumentError.new("The argument passed must be a String") unless text.is_a?(String)
      return [] if text.empty?

      setup(text)

      create_array_elements
      find_abbreviations_and_join_strings
      split_enklitika_and_change_their_position
      merge_what_needs_merging # quam diu => quamdiu
      tokens = create_tokens

      add_to << tokens if add_to.respond_to?(:<<)
      tokens
    end

    def setup(text, worker = [])
      @text = text
      @worker = worker # can be setup for easier testing
    end

  ######################

    # "Atque M. Cicero mittit" to %w{ Atque M . Cicero mittit }

    PUNCTUATION = /([\.\?,!;\-:"\(\)\[\]†])/
    def create_array_elements
      @worker = @text.gsub(PUNCTUATION, ' \1 ').split
    end

  ######################

    # covers abbreviated Roman praenomen like Ti. in Ti. Claudius Nero
    # covers Roman date expression like a. d. V. Kal. Apr.
    ABBREVIATIONS = /^(#{ALL_ABBRS_PIPED})$/

    # %w{ Atque M . Cicero mittit } to %w{ Atque M. Cicero mittit }

    def find_abbreviations_and_join_strings
      arr = []
      @worker.each_with_index do |e, i|
        n = @worker[i + 1]
        if e =~ ABBREVIATIONS && n == "."
          @worker[i + 1] = n.prepend(e)
          arr << (i - arr.size)
        end
      end

      arr.each { |i| @worker.delete_at(i) }
      @worker
    end

  ######################

    WORDS_ENDING_WITH_QUE = [ /^([qc]u[ei].*que|qu[ao]que|itaque|atque|neque|ut[er].*que|plerumque|denique|undique)$/i ]
    WORDS_ENDING_WITH_NE  = [ /^(omne|sine|bene|paene)$/i ]

    # laetusque  to -que laetus
    # in eoque   to -que in eo
    # honestumne to -ne honestum
    #
    # but
    #
    # uterque, institutione et al. remain

    def split_enklitika_and_change_their_position
      # uses brute force at first
      split_enklitikon("-que", WORDS_ENDING_WITH_QUE)
      # the restrictor array handles only obvious cases
      split_enklitikon("-ne", WORDS_ENDING_WITH_NE)

      # others might be later implemented after the full db_search
      make_frequent_corrections
      @worker
    end

    def split_enklitikon(word, restrictors, alloweds = [])
      regexp = /(?<=\w)#{word[1..-1]}$/  # needs a word character in front - ne itself should be contained

      indices = []
      @worker.each_with_index do |x,i|
        if x.match(regexp) && restrictors.none? { |y| y.match(x) }
          x.slice!(regexp)
          indices << i + indices.size
        end
      end

      indices.each { |i| @worker.insert(i, word) }
    end

    def make_frequent_corrections
      ne_corrections
      que_corrections
    end

    def to_be_shifted_que_indices
      # double shifts would properly fail, but they  might never happen
      @worker.each_with_index.each_with_object([]) do |(element, index), accumulator|
        accumulator << index if element == "-que" && @worker[index - 1] =~ /^(in|ad|ob)$/ # and others
      end
    end

    def que_corrections
      to_be_shifted_que_indices.each { |i| @worker.insert(i - 1, @worker.delete_at(i)) }
    end

    def ne_corrections
      correct = []
      @worker.each_with_index do |w, i|
        if w == "-ne"
          next_el = @worker[i + 1]

          entries = []
          entries += lookup(next_el, :noun, :nom)           if next_el =~ /io$/   # actio-ne ratio-ne
          entries += lookup(next_el + "n", :persona, :stem) if next_el =~ /o$/    # Plato-ne Cicero-ne Solo-ne
          entries += lookup(next_el + "n", :noun, :stem)    if next_el =~ /d?i$/  # fortitudi-ne ratio-ne libidi-ne homi-ne
          entries += lookup(next_el + "n", :noun, :stem)    if next_el =~ /mi$/   # flumi-ne agmi-ne
          entries += lookup(next_el + "n", :adjective, :stem)                     # communis commune

          if entries.any?(&:third_decl_with_possible_ne_abl?)
            correct << i - correct.size
          end
        end
      end

      correct.each { |i| @worker[i + 1] << @worker.delete_at(i)[1..-1] }
    end

    def lookup(string, type, column, inflection_class = 3)
      string = (type == :persona ? string : string.downcase)
      query = {
                type: type, stem_type: column, stem: string,
                restrictions: { type: :inflection_class, values: [inflection_class] }
              }
      @db.look_up_stem(query)
    end


  ######################

    MERGE_WORDS = [ %w{ quam diu } ]

    # quam diu to quamdiu

    def merge_what_needs_merging
      to_delete = []
      arr = ArrayScanner.new(@worker)

      until arr.eoa?
        arr.scan
        pair = [arr.last_result.downcase, arr.current]
        merge_words(arr, to_delete) if MERGE_WORDS.include?(pair)
      end

      @worker -= to_delete
    end

    def merge_words(arr, to_delete)
      arr.last_result << arr.current_element
      to_delete       << arr.current_element
    end

  ######################

    ABBR_NAME_WITH_DOT       = /^(#{NAMES_PIPED})\.$/
    ROMAN_DATE_EXPR_WITH_DOT = /^(#{DATES_PIPED})\.$/

    def create_tokens
      @worker.map! do |el|
        case el
        when ABBR_NAME_WITH_DOT       then LLT::Filler.new(el)
        when ROMAN_DATE_EXPR_WITH_DOT then LLT::Filler.new(el)
        when PUNCTUATION              then LLT::Punctuation.new(el)
        else                               LLT::Word.new(el)
        end
      end
    end
  end
end
