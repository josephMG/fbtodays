module FbtodaysHelper

    #used in photo template
    def autolink_truncate(msg)
        str=auto_link(msg) 
        index=str.index("</a>")
        index=100 if index.nil? || index < 100
        simple_format_msg(str,index+"**link**</a>".length)
    end
    
    private
    def simple_format_msg(str, len)
        return simple_format(truncate(str, :length => len, :separator => ' '),{},wrapper_tag:"span")
    end
end
