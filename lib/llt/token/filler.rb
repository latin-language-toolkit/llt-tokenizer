module LLT
  class Token
    class Filler < Token
      def add(type)
        case type
        when :name then add_name_form
        end
      end

      #def add_name_form
      #  @possible_forms << PersonaFiller.new(@word)
      #end

      # cannot hold anything atm, is therefore never really empty
      def empty?
        false
      end
      alias :no_forms? :empty?

      def set_functions
        [:filler]
      end

      def inspect
        "#{"Filler token".blue}: #{@string}"
      end
    end
  end
end
