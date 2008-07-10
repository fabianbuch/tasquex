require 'rubygems' # TODO remove and include ext libs into distribution
require 'rtmilk'

class RTM::API
  
  # invoke a method
  def invoke
    p make_url
    # sleep one second to not get banned from RTM
    sleep 1 if defined?(@@last_request) && (Time.now - @@last_request) < 1
    response = Net::HTTP.get(RTM_URI, make_url)
    
    result = XmlSimple.new.xml_in(response)
    ret = parse_result(result)
  ensure
    @@last_request = Time.now
  end
  
end

class RTM::Task
  
  def self.find_by_id(list_id, id)
    all_tasks(list_id).find do |task|
       task.id == id
    end
  end
  
end

module TasqueX
  
  class RtmStore
    
    API_KEY       = 'f777b4bcbda99484bd823c9c301e6dca'
    SHARED_SECRET = 'f59e95985a21acc1'
    
    def initialize
      @authenticated = false
      @token_persisted = false # TODO read persisted token
      
      # provide APP_KEY and SHARED_SECRET for RTM::API
      RTM::API.init(API_KEY, SHARED_SECRET, {:token => @token_persisted})

      # get frob
      @frob = RTM::Auth::GetFrob.new.invoke
    end
    
    def authenticate
      # get auth url for read
      url = RTM::API.get_auth_url('delete', @frob)
      puts url

      # open auth url in browser
      `open '#{url}'`
      
      @authenticated = true
    end
    
    def authenticated?
      
      if @authenticated && !@token_persisted && !(RTM::API.token rescue nil)
        res = RTM::Auth::GetToken.new(@frob).invoke
        RTM::API.token = res[:token]
      else
        return false
      end
      
      @authenticated = RTM::API.token ? true : false
    end
    
    def all_lists
      lists = []
      
      RTM::List.alive_all do |list|
        p list
        lists << List.new(list.id, list.name)
      end
      
      lists
    end
    
    def all_tasks
      tasks = []
      
      RTM::Task.find_all({}).each do |r_task|
        task = Task.new
        
        task.name = r_task.name
        task.id = r_task.id
        task.priority = r_task.chunks.first.priority.to_i
        task.due = r_task.chunks.first.due
        task.completed = r_task.chunks.first.completed
        task.list_id = r_task.list
        
        tasks << task
      end
      
      tasks
    end
    
    def all_tasks_in_list(list_id)
      tasks = []
      
      RTM::Task.find_all({:list => list_id}).each do |r_task|
        task = Task.new
        
        task.name = r_task.name
        task.id = r_task.id
        task.priority = r_task.chunks.first.priority.to_i
        task.due = r_task.chunks.first.due
        task.completed = r_task.chunks.first.completed
        task.list_id = r_task.list
        
        tasks << task
      end
      
      tasks
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
        p "ERROR: edit_task(task) not implemented"
      else
        raise ArgumentError.new("should be of Type 'Task'")
      end
    end
    
  end
  
end
