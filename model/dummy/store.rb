module TasqueX
  
  class DummyStore
    
    def initialize
      @authenticated = true
      
      @lists = []
      @lists << List.new(1,"Dummy")
      @lists << List.new(2,"Offline")
      
      @tasks = []
      task1 = Task.new
      task1.id = 1
      task1.name = "Dummy Task"
      task1.priority = "2"
      task1.due = "#{Time.now + 2400}"
      task1.list_id = 1
      
      @tasks << task1
      
      task2 = Task.new
      task2.id = 2
      task2.name = "Test TasqueX"
      task2.completed = "#{Time.now}"
      task2.due = "#{Time.now + 4400}"
      task2.list_id = 2
      
      @tasks << task2
      
      task3 = Task.new
      task3.id = 3
      task3.name = "buy milk"
      task3.completed = "#{Time.now - 2000}"
      task3.due = "#{Time.now + 1400}"
      task3.list_id = 2
      
      @tasks << task3
    end
    
    def authenticate
      @authenticated = true
    end
    
    def authenticated?
      @authenticated
    end
    
    def all_lists
      @lists
    end
    
    def all_tasks
      @tasks
    end
    
    def all_tasks_in_list(list_id)
      [@tasks.find { |t| t.list_id == list_id  }].flatten
    end
    
    def add_task(list_id, name)
      task = Task.new
      task.list_id = list_id
      task.id = task.object_id
      task.name = name
      
      @tasks << task
    end
    
    def delete_task(task)
      if task.class == Task
        @tasks.delete_if { |t| t.id == task.id }
      else
        raise ArgumentError.new("should be of Type 'Task'")
      end
    end
    
    def edit_task(task)
      if task.class == Task
        index = @tasks.index(@tasks.find { |t| t.id == task.id })
        @tasks[index] = task
      else
        raise ArgumentError.new("should be of Type 'Task'")
      end
    end
    
  end
  
end
