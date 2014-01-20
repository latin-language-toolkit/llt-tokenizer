require 'xml_escape'

module LLT
  class Token
    class Punctuation < Token
      xml_tag 'pc'

      include XmlEscape

      attr_accessor :opening, :closing, :other

      def initialize(string, id = nil)
        super
        # this is part of an old interface that is mostly unused
        # some parts remain - find and delete em
        @string = xml_decode(string)
        @opening = false
        @closing = false
        @other   = false
      end

      # cannot hold anything atm, is therefore never really empty
      def empty?
        false
      end
      alias :no_forms? :empty?

      def set_functions
        [:punctuation]
      end

      def punctuation
        @string
      end

      def inspect
        "#{"Punctuation token:".yellow} #{@string}"
      end

      def as_xml
        xml_encode(@string)
      end
    end
  end
end
