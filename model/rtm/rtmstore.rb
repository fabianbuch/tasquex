require 'rubygems' # TODO remove and include ext libs into distribution
require 'rtmilk'

module RTM

class API
  
  # invoke a method
  def invoke
    # sleep one second to not get banned from RTM
    sleep 1 if defined?(@@last_request) && (Time.now - @@last_request) < 1
    response = Net::HTTP.get(RTM_URI, make_url)
    
    result = XmlSimple.new.xml_in(response)
    ret = parse_result(result)
  ensure
    @@last_request = Time.now
  end
  
end

class Task
  
  def self.find_by_id(list_id, id)
    all_tasks(list_id).find do |task|
       task.id == id
    end
  end
  
end

module Tasks

  class SetName < RTM::API
    def parse_result(result)
      super
      [result['list'].first['taskseries'].first, result['transaction'].first]
    end
    
    def initialize(token, timeline, list_id, taskseries_id, chunk_id, name)
      super 'rtm.tasks.setName', token
      @param[:timeline] = timeline
      @param[:list_id] = list_id
      @param[:taskseries_id] = taskseries_id
      @param[:task_id] = chunk_id
      @param[:name] = name
    end
  end # SetName

  class SetDueDate < RTM::API
    def parse_result(result)
      super
      [result['list'].first['taskseries'].first, result['transaction'].first]
    end
    
    def initialize(token, timeline, list_id, taskseries_id, chunk_id, due, has_due_time = nil, parse = nil)
      super 'rtm.tasks.setDueDate', token
      @param[:timeline] = timeline
      @param[:list_id] = list_id
      @param[:taskseries_id] = taskseries_id
      @param[:task_id] = chunk_id
      @param[:due] = due
      @param[:has_due_time] = has_due_time if has_due_time
      @param[:parse] = parse ? parse : 1
    end
  end # SetDueDate

  class SetPriority < RTM::API
    def parse_result(result)
      super
      [result['list'].first['taskseries'].first, result['transaction'].first]
    end
    
    def initialize(token, timeline, list_id, taskseries_id, chunk_id, priority)
      super 'rtm.tasks.setPriority', token
      @param[:timeline] = timeline
      @param[:list_id] = list_id
      @param[:taskseries_id] = taskseries_id
      @param[:task_id] = chunk_id
      @param[:priority] = priority
    end
  end # SetPriority

  class Complete < RTM::API
    def parse_result(result)
      super
      [result['list'].first['taskseries'].first, result['transaction'].first]
    end
    
    def initialize(token, timeline, list_id, taskseries_id, chunk_id)
      super 'rtm.tasks.complete', token
      @param[:timeline] = timeline
      @param[:list_id] = list_id
      @param[:taskseries_id] = taskseries_id
      @param[:task_id] = chunk_id
    end
  end # Complete

  class Uncomplete < RTM::API
    def parse_result(result)
      super
      [result['list'].first['taskseries'].first, result['transaction'].first]
    end
    
    def initialize(token, timeline, list_id, taskseries_id, chunk_id)
      super 'rtm.tasks.uncomplete', token
      @param[:timeline] = timeline
      @param[:list_id] = list_id
      @param[:taskseries_id] = taskseries_id
      @param[:task_id] = chunk_id
    end
  end # Uncomplete


end # Tasks

end # RTM

module TasqueX
  
  class RtmStore
    
    API_KEY       = 'f777b4bcbda99484bd823c9c301e6dca'
    SHARED_SECRET = 'f59e95985a21acc1'
    
    def initialize
      @authenticated = false
      @persisted_token =  OSX::NSUserDefaultsController.sharedUserDefaultsController.values.valueForKey('rtmtoken').to_s
      
      # provide APP_KEY and SHARED_SECRET for RTM::API
      RTM::API.init(API_KEY, SHARED_SECRET, {:token => @persisted_token})
      
      # get frob
      @frob = RTM::Auth::GetFrob.new.invoke
    end
    
    def authenticate
      if @persisted_token.empty?
        # get auth url for read
        url = RTM::API.get_auth_url('delete', @frob)
        
        # open auth url in browser
        `open '#{url}'`
      end
      
      @authenticated = true
    end
    
    def authenticated?
      if !@persisted_token.empty?
        begin
          RTM::Auth::CheckToken.new(@persisted_token).invoke
          RTM::API.token = @persisted_token
          @authenticated = true
        rescue
          @persisted_token = ""
          @authenticated = false
        end
      else
        if @authenticated
          res = RTM::Auth::GetToken.new(@frob).invoke
          RTM::API.token = res[:token]
          persist_token(res[:token])
          @authenticated = true
        else
          @authenticated = false
        end
      end
      
      @authenticated
    end
    
    def persist_token(token)
       authCacheEnabled =  OSX::NSUserDefaultsController.sharedUserDefaultsController.values.valueForKey('authCache').to_s
       if authCacheEnabled == '1'
         OSX::NSUserDefaultsController.sharedUserDefaultsController.values.setValue_forKey(
          token.to_s, 'rtmtoken' 
        )
      end
    end
    
    def all_lists
      lists = []
      
      RTM::List.alive_all.each do |list|
        lists << List.new(list.id, list.name)
      end
      
      lists
    end
    
    def all_tasks
      all_tasks_in_list(nil)
    end
    
    def all_tasks_in_list(list_id)
      tasks = []
      
      RTM::Task.find_all({:list => list_id}).each do |r_task|
        task = Task.new
        
        task.name = r_task.name
        task.id = r_task.id
        task.chunk_id = r_task.chunks.first.id
        task.priority = r_task.chunks.first.priority.to_i
        task.due = r_task.chunks.first.due
        task.completed = r_task.chunks.first.completed
        task.list_id = r_task.list
        
        tasks << task
      end
      
      tasks
    end
    
    def all_incomplete_tasks(list_id = nil)
      [all_tasks_in_list(list_id).find_all { |t| t.completed.to_s.empty? }].flatten.compact
    end
    
    def all_complete_tasks(list_id = nil)
      [all_tasks_in_list(list_id).find_all { |t| !t.completed.to_s.empty? }].flatten.compact
    end
    
    def add_task(list_id, name)
      timeline = RTM::Timeline.new(RTM::API.token)
      
      if list_id.to_i == 0
        list_id = RTM::List.find("Inbox")["id"]
      end
      RTM::Tasks::Add.new(RTM::API.token, timeline, list_id, name.to_s).invoke
      
    end
    
    def delete_task(task)
      if task.class == Task
        RTM::Task.find_by_id(task.list_id, task.id).delete
      else
        raise ArgumentError.new("should be of Type 'Task'")
      end
    end
    
    def edit_task(task)
      if task.class == Task
        timeline = RTM::Timeline.new(RTM::API.token)
        RTM::Tasks::SetName.new(RTM::API.token, timeline, task.list_id, task.id, task.chunk_id, task.name).invoke
        RTM::Tasks::SetDueDate.new(RTM::API.token, timeline, task.list_id, task.id, task.chunk_id, task.due).invoke
        RTM::Tasks::SetPriority.new(RTM::API.token, timeline, task.list_id, task.id, task.chunk_id, task.priority).invoke
        if task.completed.to_s.empty?
          RTM::Tasks::Uncomplete.new(RTM::API.token, timeline, task.list_id, task.id, task.chunk_id).invoke
        else
          RTM::Tasks::Complete.new(RTM::API.token, timeline, task.list_id, task.id, task.chunk_id).invoke
        end
      else
        raise ArgumentError.new("should be of Type 'Task'")
      end
    end
    
  end
  
end
