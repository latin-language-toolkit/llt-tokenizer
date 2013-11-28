require 'array_scanner'
require 'forwardable'

module LLT
  class Tokenizer
    class Worker
      extend Forwardable
      include Enumerable
      include Helpers::Metrical

      def_delegators :@bare_text, :each, :[], :[]=, :insert, :delete_at, :each_overlapping_pair,
                            :map!

      def initialize(metrical_text, enclitics, shifting, marker)
        @metrical_text = metrical_text
        @bare_text     = metrical_text.map { |token| wo_meter(token) }
        @enclitics     = enclitics
        @unmarked_encl = enclitics.map { |encl| encl.dup.delete(marker) }
        @shifitng      = shifting
        @marker        = marker
      end

      def to_a
        align_metrical_text
        @metrical_text
      end

      private

      # One ugly method, but we don't want to slow it down even more
      def align_metrical_text
        m = ArrayScanner.new(@metrical_text)
        b = ArrayScanner.new(@bare_text)
        loop do
          x = m.scan
          y = b.scan
          no_meter = wo_meter(x)
          unless no_meter == y
            if @enclitics.include?(y)
              # metrical text will have the encl y at its current position and
              # in rare cases on the position right after
              clean_encl_re = /#{y.dup.delete(@marker)}$/
              unless index = no_meter =~ clean_encl_re
                x = m.current
                index = wo_meter(x) =~ clean_encl_re
              end
              insert!(slice_encl!(x, index), m.pos - 1)
            elsif encl = @unmarked_encl.find { |e| no_meter.end_with?(e) }
              index = no_meter =~ /#{encl}$/
              insert!(slice_encl!(x, index), m.pos)
            elsif y.end_with?('.') && m.current == '.'
              append_from_index!(x, m.pos)
            end
          end
          break if b.eoa?
        end
      end

      def insert!(enclitic, position)
        @metrical_text.insert(position, "#{@marker}#{enclitic}")
      end

      def slice_encl!(token, index)
        token.slice!(index..-1)
      end

      def append_from_index!(token, index)
        token << @metrical_text.delete_at(index)
      end
    end
  end
end
