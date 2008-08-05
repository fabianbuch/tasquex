require 'date'

module TasqueX
  class Task
    
    attr_accessor :id
    attr_accessor :chunk_id # for RTM (rtmilk), obsolete for other stores
    attr_accessor :name # String
    attr_accessor :completed # DateTime of completion date
    attr_accessor :priority # Integer
    attr_accessor :due # DateTime of due date
    
    attr_accessor :list_id
    
    def <=>(other)
      if (completed.to_s.size <=> other.completed.to_s.size) != 0
        completed.to_s.size <=> other.completed.to_s.size
      elsif due && other.due && ((due.to_s <=> other.due.to_s) != 0)
        if due.to_s.empty? || other.due.to_s.empty?
          due.to_s.empty? ? -1 : 1
        else
          Date.parse(due.to_s) <=> Date.parse(other.due.to_s)
        end
      elsif (priority.to_i <=> other.priority.to_i) != 0
        -(priority.to_i <=> other.priority.to_i)
      elsif (id.to_s <=> other.id.to_s) != 0
        id.to_s <=> other.id.to_s
      else
        name.to_s <=> other.name.to_s
      end
    end
    
  end
end