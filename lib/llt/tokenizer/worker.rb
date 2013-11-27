require 'forwardable'

module LLT
  class Tokenizer
    class Worker
      extend Forwardable
      include Enumerable

      def_delegators :@raw, :each, :[], :[]=, :insert, :delete_at, :each_overlapping_pair,
                            :map!, :to_a

      def initialize(text)
        @text = text
      end

      def create_array_elements
        @raw = @text.gsub(PUNCTUATION, ' \1 ').split
      end

      def self.setup(arr)
        obj = allocate
        obj.instance_variable_set(:@raw, arr)
        obj
      end
    end
  end
end
