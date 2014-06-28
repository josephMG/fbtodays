#encoding utf-8
class FbMessage
    def self.test(message)
        message.inspect
    end
    def initialize(message)
        @fb_message=message
    end
    def get_type
        f_msg=fb_message["type"]
        if f_msg == "photo"
            return "照片"
        elsif f_msg == "video"
            return "影片"
        elsif f_msg == "link"
            return "分享"
        elsif f_msg == "status"
            return "動態"
        else 
            return f_msg
        end
    end
    def template_type
# choose template
        f_msg=fb_message["type"]
        if f_msg!="photo" && f_msg!="link" && f_msg!="status" && f_msg!="video"
            return "photo" 
        end
        if f_msg.nil?
            return "photo" 
        end
        f_msg
    end
    def fb_message
        @fb_message
    end
end
