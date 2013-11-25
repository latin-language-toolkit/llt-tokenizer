module LLT
  class Token
    class Word < Token
      def word
        @string
      end

      def no_forms?
        @container.empty?
      end

      def set_functions
        [:word]
      end

      def use(i = nil)
        if i
          return @container[i - 1]
        elsif block_given?
          @container.find { |f| yield(f) }
        end
      end

      def inspect
        "#{"Word token".green}: #{@string}\n" +
        "\tForms: #{forms_to_s}\n"
      end

      def forms_to_s
        # was each_with_index_and_object, which is currently not available
        @container.each_with_index.each_with_object("") do |(f, i), str|
          str << enumeration(i) << stripped_form(f)
          str << delimiter unless f == @container.last
          str
        end
      end

      def stripped_form(form)
        form.to_s.sub(@string, "").strip
      end

      def enumeration(i)
        "#{i}: ".light_yellow
      end

      def delimiter
        " | ".cyan
      end
    end
  end
end
