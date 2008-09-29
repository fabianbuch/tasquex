require 'sequel'

module TasqueX
  
  class SequelStore
    
    @DB_PATH = ENV['HOME'] + "/Library/Application\ Support/tasqueX/sqlite.db"
    
    def initialize
      @DB = Sequel.sqlite(@DB_PATH)
      
      @authenticated = true
      
      @lists = []
      
      @tasks = []
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
