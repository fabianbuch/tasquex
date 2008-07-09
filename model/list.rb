module TasqueX
  class List
    
    attr_accessor :id
    attr_accessor :name
    
    def initialize(id, name)
      @id = id
      @name = name
    end
    
    def <=>(other)
      id <=> other.id
    end
    
  end
end