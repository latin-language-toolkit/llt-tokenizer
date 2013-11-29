module LLT
  class Token
    class XmlTag < Token
      def set_functions
        [:xml_tag]
      end

      # overrides #to_xml from Containable - the tag stays at is it
      def to_xml(*args)
        to_s
      end
    end
  end
end
