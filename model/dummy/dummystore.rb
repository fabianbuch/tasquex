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
      task1.due = "#{Time.now + 24400}"
      task1.list_id = 1
      
      @tasks << task1
      
      task2 = Task.new
      task2.id = 2
      task2.name = "Test TasqueX"
      task2.completed = "#{Time.now}"
      task2.due = "#{Time.now + 24400}"
      task2.list_id = 2
      
      @tasks << task2
      
      task3 = Task.new
      task3.id = 3
      task3.name = "buy milk"
      task3.completed = "#{Time.now - 2000}"
      task3.due = "#{Time.now + 11400}"
      task3.list_id = 2
      
      @tasks << task3
      
      task4 = Task.new
      task4.id = 3
      task4.name = "kiss wife"
      task4.priority = 3
      task4.due = "#{Time.now - 121400}"
      task4.list_id = 2
      
      @tasks << task4
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
      if list_id != nil
        [@tasks.find_all { |t| t.list_id == list_id  }].flatten.compact
      else
        @tasks
      end
    end
    
    def all_incomplete_tasks(list_id = nil)
      [all_tasks_in_list(list_id).find_all { |t| t.completed.to_s.empty? }].flatten.compact
    end
    
    def all_complete_tasks(list_id = nil)
      [all_tasks_in_list(list_id).find_all { |t| !t.completed.to_s.empty? }].flatten.compact
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
