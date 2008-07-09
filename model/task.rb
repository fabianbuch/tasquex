module TasqueX
  class Task
    
    attr_accessor :id
    attr_accessor :name # String
    attr_accessor :completed # String of completion date
    attr_accessor :priority # Integer
    attr_accessor :due # due date
    
    attr_accessor :list_id
    
    def <=>(other)
      completed.to_s.size <=> other.completed.to_s.size ||
      priority.to_i <=> other.priority.to_i ||
      due.to_s <=> other.due.to_s ||
      id.to_s <=> other.id.to_s ||
      name.to_s <=> other.name.to_s
    end
    
  end
end