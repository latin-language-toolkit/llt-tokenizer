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
        aligned = []
        m = ArrayScanner.new(@metrical_text)
        b = ArrayScanner.new(@bare_text)
        loop do
          x = m.scan
          y = b.scan
          no_meter = wo_meter(x)

          if no_meter == y
            aligned << x
          elsif @enclitics.include?(y)
            # metrical text will have the encl y at its current position and
            # in rare cases on the position right after
            index = no_meter =~ /#{y.dup.delete(@marker)}$/
            encl_w_meter = x.slice!(index..-1)
            m.to_a.insert(m.pos - 1, "#{@marker}#{encl_w_meter}")
            aligned << x
          elsif encl = @unmarked_encl.find { |e| no_meter.end_with?(e) }
            index = no_meter =~ /#{encl}$/
            encl_w_meter = x.slice!(index..-1)
            m.to_a.insert(m.pos, "#{@marker}#{encl_w_meter}")
            aligned << x
          elsif y.end_with?('.') && m.current == '.'
            x << m.to_a.delete_at(m.pos)
            aligned << x
          end
          break if b.eoa?
        end
      end
    end
  end
end
