module TasqueX
  class Task
    
    attr_accessor :id
    attr_accessor :name # String
    attr_accessor :completed # String of completion date
    attr_accessor :priority # Integer
    attr_accessor :due # due date
    
    attr_accessor :list_id
    
    def <=>(other)
      p "#{name} other: #{other.name}"
      if completed && other.completed && due && other.due && priority && other.priority && id && other.id
        completed <=> other.completed &&
        due <=> other.due &&
        priority <=> other.priority &&
        id <=> other.id
      elsif due && other.due && priority && other.priority && id && other.id
        due <=> other.due &&
        priority <=> other.priority &&
        id <=> other.id
      elsif priority && other.priority && id && other.id
        priority <=> other.priority &&
        id <=> other.id
      elsif id && other.id
        id <=> other.id
      else
        name <=> other.name
      end
    end
    
  end
end