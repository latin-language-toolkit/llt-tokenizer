module LLT
  class Tokenizer
    module Greek
      PLAIN_VOWELS = %w(α ε ι η ο υ ω)
      VOWELS_WITH_ACUTE = %w(ά έ ή ί ó ύ ώ)
      VOWELS_WITH_GRAVE = %w(ὰ ὲ ὴ ì ò ὺ ὼ)
      VOWELS_WITH_CIRCUMFLEX = %w(ᾶ ῆ ῖ ῦ ῶ)
      VOWELS_WITH_IOTA = %w(ᾲ ᾳ ᾴ ᾷ ῂ ῃ ῄ ῇ ῲ ῳ ῴ ῷ)
      CONSONANTS = %w(β γ δ ζ θ κ λ μ ν ξ π ρ ῥ ῤ σ ς τ φ χ ψ)
      VOWELS = [PLAIN_VOWELS,
                VOWELS_WITH_ACUTE,
                VOWELS_WITH_GRAVE,
                VOWELS_WITH_CIRCUMFLEX,
                VOWELS_WITH_IOTA
      ].flatten

      SPIRITUS_LENIS = %w(ἀ ἐ ἠ ἰ ὀ ὐ ὠ)
      SPIRITUS_LENIS_WITH_GRAVE = %w(ἂ ἒ ἲ ἢ ὂ ὒ ὢ)
      SPIRITUS_LENIS_WITH_ACUTE = %w(ἄ ἔ ἴ ἤ ὄ ὔ ὤ)
      SPIRITUS_LENIS_WITH_CIRCUMFLEX = %w(ἆ ἶ ἦ ὖ ὦ )

      SPIRITUS_ASPER = %w(ἁ ἑ ἡ ἱ ὁ ὑ ὡ)
      SPIRITUS_ASPER_WITH_GRAVE = %w(ἃ ἣ ἓ ἳ ὃ ὓ ὣ)
      SPIRITUS_ASPER_WITH_ACUTE = %w(ἅ ἥ ἕ ἵ ὅ ὕ ὥ)
      SPIRITUS_ASPER_WITH_CIRCUMFLEX = %w(ἇ ἷ ἧ ὗ ὧ)

      SPIRITUS_WITH_IOTA = %w(ᾀ ᾁ ᾂ ᾃ ᾄ ᾅ ᾆ ᾇ ᾐ ᾑ ᾒ ᾓ ᾔ ᾕ ᾖ ᾗ ᾠ ᾡ ᾢ ᾣ ᾤ ᾥ ᾦ ᾧ)

      VOWELS_WITH_SPIRITUS = [
        SPIRITUS_LENIS,
        SPIRITUS_LENIS_WITH_ACUTE,
        SPIRITUS_LENIS_WITH_GRAVE,
        SPIRITUS_LENIS_WITH_CIRCUMFLEX,
        SPIRITUS_ASPER,
        SPIRITUS_ASPER_WITH_ACUTE,
        SPIRITUS_ASPER_WITH_GRAVE,
        SPIRITUS_ASPER_WITH_CIRCUMFLEX,
        SPIRITUS_WITH_IOTA
      ].flatten

      STARTING_VOWELS = Regexp.union(VOWELS_WITH_SPIRITUS)
      CONS = Regexp.union(CONSONANTS)
      ALL = Regexp.union([CONSONANTS, VOWELS].flatten)

      def split_krasis
        @worker.each_with_index do |token, i|
          if resolved_krasis = contains_krasis(token)
            @worker[i] = resolved_krasis
            @worker.flatten!
          end
        end
      end

      def krasis(token)
        "#{token}#{@krasis_marker}"
      end

      def contains_krasis(token)
        if token.match(/^(#{CONS})(#{PLAIN_VOWELS}?#{STARTING_VOWELS})(#{ALL}*)$/)
          [$1, $2+$3]
        end
      end

    end
  end
end
