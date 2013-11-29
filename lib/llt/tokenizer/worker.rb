require 'array_scanner'
require 'forwardable'

module LLT
  class Tokenizer
    class Worker
      extend Forwardable
      include Enumerable
      include Helpers::Metrical

      def_delegators :@bare_text, :each, :[], :[]=, :insert, :delete_at,
                                  :each_overlapping_pair, :map!

      # TODO 28.11.13 11:45 by LFDM
      # Edge cases?
      # Merge words?

      def initialize(metric_text, marker)
        @metric_text = metric_text
        @bare_text     = metric_text.map { |token| wo_meter(token) }
        @marker        = marker
        @marked_enclitics = ENCLITICS.map { |e| "#{@marker}#{e}"}
      end

      def to_a
        align_metrical_text
        @metric_text
      end

      private

      # One ugly method, but we don't want to slow it down even more
      def align_metrical_text
        m = ArrayScanner.new(@metric_text)
        b = ArrayScanner.new(@bare_text)
        loop do
          # metric element
          x = m.scan
          # bare element
          y = b.scan
          no_meter = wo_meter(x)

          # we don't have to do anything if the dequantified metric element
          # was the same as the bare element - the metric_text was right
          # at this position
          unless no_meter == y

            # If the bare element was a marked enclitic, it must have been
            # shifted. We're looking for the next metric token, that has it
            # attached and try to find the string index where it starts to
            # slice it of.
            # Usually the metric element just scanned (y) will have it, if we
            # don't find it, a double shift has occured and it should sit right
            # at the current element of the metric ArrayScanner (m).
            # The enclitic (sliced of x) has to be inserted one position before.
            if @marked_enclitics.include?(y)
              clean_encl_re = /#{y.dup.delete(@marker)}$/
              unless index = no_meter =~ clean_encl_re
                x = m.current
                index = wo_meter(x) =~ clean_encl_re
              end
              insert!(slice_encl!(x, index), m.pos - 1)

            # If the dequantified metric element has an enclitic attached, the
            # option shifting: false must have been given. The enclitic will
            # follow right after in the @bare_text, we can therefore slice and
            # insert right in place (the next # scan round will reveal that
            # enclitic in metric_text == enclitic in bare_text
            elsif encl = ENCLITICS.find { |e| no_meter.end_with?(e) }
              index = no_meter =~ /#{encl}$/
              insert!(slice_encl!(x, index), m.pos)

            # If the bare element has a dot attached, it must have been an
            # abbreviation.
            # The . will appear right afterwards in the metric text. We can
            # delete it and append it to the last scanned metric element (x)
            #
            # We need to do the same if merge words were present.
            # The last metric element was quam, the bare element is quamdiu.
            # We append if the last metric element + the next metric element
            # is the same as the bare element.
            elsif y.end_with?('.') || merged_words_present?(no_meter, y, m)
              append_from_deleted_index!(x, m.pos)
            end
          end
          break if b.eoa?
        end
      end

      def insert!(enclitic, position)
        @metric_text.insert(position, "#{@marker}#{enclitic}")
      end

      def slice_encl!(token, index)
        token.slice!(index..-1)
      end

      def append_from_deleted_index!(token, index)
        token << @metric_text.delete_at(index)
      end

      def merged_words_present?(last_metric, last_bare, metric_arr_scanner)
        (last_metric + wo_meter(metric_arr_scanner.peek)) == last_bare
      end
    end
  end
end
