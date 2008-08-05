require 'date'

module TasqueX
  class DateTime < DateTime
    
    def to_pretty_s
      pretty_date = ""
      now = TasqueX::DateTime.now
      
      if self.year == now.year
        if self.yday == now.yday
          pretty_date = self.strftime("Today, %m/%d")
        elsif self.yday < now.yday && self.yday == now.yday - 1
          pretty_date = self.strftime("Yesterday, %m/%d")
        elsif self.yday < now.yday && self.yday > now.yday - 6
          pretty_date = "#{now.yday - self.yday} days ago"
        elsif self.yday > now.yday && self.yday == now.yday + 1
          pretty_date = self.strftime("Tomorrow, %m/%d")
        elsif self.yday > now.yday && self.yday < now.yday + 6
          pretty_date = "In #{self.yday - now.yday} days"
        else
          pretty_date = self.strftime("%B %d")
        end
      elsif self == TasqueX::DateTime.new(0)
        pretty_date = "No Date"
      else
        pretty_date = self.strftime("%B %d %Y")
      end
      
      pretty_date
    end
    
    def sevendays
      days = []
      
      days << self.strftime("Today, %m/%d")
      days << (self+1).strftime("Tomorrow, %m/%d")
      days << (self+2).strftime("%A, %m/%d")
      days << (self+3).strftime("%A, %m/%d")
      days << (self+4).strftime("%A, %m/%d")
      days << (self+5).strftime("%A, %m/%d")
      days << (self+6).strftime("%A, %m/%d")
      
      days
    end
    
  end
end
