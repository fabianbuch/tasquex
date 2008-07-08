#
#  controller.rb
#  tasqueX
#
#  Created by Fabian Buch on 02.07.08.
#  Copyright (c) 2008 Fabian Buch. All rights reserved.
#

require 'rubygems' # TODO remove and include ext libs into distribution
require 'rtmilk'

require 'model/store'

require 'osx/cocoa'

$ONLINE = false

class RTM::API
  
  # invoke a method
  def invoke
    p make_url
    sleep 1 if defined?(@@last_request) && (Time.now - @@last_request) < 1
    response = Net::HTTP.get(RTM_URI, make_url)
    
    result = XmlSimple.new.xml_in(response)
    ret = parse_result(result)
  ensure
    @@last_request = Time.now
  end
  
end


class Controller < OSX::NSObject
  include OSX

  ib_outlet :mainWindow, :authWindow
  ib_outlet :tableTasks
  
  ib_outlet :inputNewTask, :buttonLists, :buttonAddTask, :buttonAuth
  
  ib_outlet :lists
  
  API_KEY       = 'f777b4bcbda99484bd823c9c301e6dca'
  SHARED_SECRET = 'f59e95985a21acc1'
  
  # like initialized, but will be called after Nib is loaded
  def awakeFromNib
    # provide APP_KEY and SHARED_SECRET for RTM::API
    RTM::API.init(API_KEY, SHARED_SECRET) if $ONLINE
    
    # get frob
    @frob = RTM::Auth::GetFrob.new.invoke if $ONLINE
    
  end
  
  def authenticate
    #begin
    #  res = RTM::Auth::CheckToken.new(persisted_token).invoke
    #  p res[:token]
    #rescue RTM::Error => e
      openAuthSheet
    #end
  end
  
  def openAuthSheet
    
    # open a modal window
      NSApp.beginSheet_modalForWindow_modalDelegate_didEndSelector_contextInfo(@authWindow, @mainWindow, self, :sheetDidEnd_returnCode_contextInfo, nil)
    
    # open auth url in browser
    authInBrowser
  end
  
  def sheetDidEnd_returnCode_contextInfo(sheet, code, context)
    sheet.orderOut(nil)
  end
  
  def authInBrowser
    # get auth url for read
    url = RTM::API.get_auth_url('delete', @frob) if $ONLINE
    puts url
    
    `open '#{url}'` if $ONLINE
  end
  
  def authNextButton
    get_token
    if !$ONLINE || RTM::API.token
      # close modal window
      NSApp.endSheet_returnCode(@authWindow, 0)
      # show hidden elements
      hide_or_show_various_elements
      
      # TODO move lists elsewhere
      if $ONLINE
        lists = RTM::List.alive_all
        lists.each do |l|
          @lists.addItemWithTitle(l.name)
          @lists.lastItem.setTag(l.id)
        end
      else
        lists = [{:name => "Offline"}]
        lists.each do |l|
          @lists.addItemWithTitle(l[:name])
        end
      end
      
      if $ONLINE
        @current_tasks = RTM::Task.find_all({})
      else
        @current_tasks = [OfflineTask.new("testname", [OfflineChunk.new("#{Time.now}", 2, "#{Time.now + 2400}")])]
      end
      
      @tableTasks.reloadData
    else
      authInBrowser
    end
  end
  
  def hide_or_show_various_elements
    @buttonAuth.setHidden(true)
    @tableTasks.setHidden(false)
    @inputNewTask.setHidden(false)
    @buttonLists.setHidden(false)
    @buttonAddTask.setHidden(false)
  end
  
  def get_token
    if $ONLINE
      res = RTM::Auth::GetToken.new(@frob).invoke
      token = res[:token]
      RTM::API.token = token
    end
  end
  
  def switchList
    menu_item = @lists.selectedItem
    @lists.selectItem(menu_item)
    
    if menu_item.title == "All"
      # select all lists
      @current_tasks = RTM::Task.find_all({})
    else
      # only this list
      @current_tasks = RTM::Task.find_all({:list => menu_item.tag})
    end if $ONLINE
    
    @tableTasks.reloadData
  end
  
  def addTask
    if @inputNewTask.stringValue.to_s.size > 0
      if $ONLINE
        timeline = RTM::Timeline.new(RTM::API.token)
        RTM::Tasks::Add.new(RTM::API.token, timeline, @lists.selectedItem.tag, @inputNewTask.stringValue.to_s).invoke
      else
        @current_tasks << OfflineTask.new(@inputNewTask.stringValue, [OfflineChunk.new("", 0, "")])
      end
      
      switchList
    end
  end
  
  def deleteTasks
    @tableTasks.selectedRowIndexes.to_a.each do |i|
      @current_tasks[i].delete
    end
    
    switchList
  end

  def tableView_setObjectValue_forTableColumn_row(table, value, column, row)
    case column.identifier
    when "check"
      if "1" == value.to_s # 1 => true (NSCFBoolean)
        @current_tasks[row].chunks.first.completed = Time.now.to_s
      else
        @current_tasks[row].chunks.first.completed = ""
      end
    when "prio"
      @current_tasks[row].chunks.first.priority = value.to_s
    when "name"
      @current_tasks[row].name = value.to_s
    when "duedate"
      @current_tasks[row].chunks.first.due = value.to_s
    end
  end

	###
  # numberOfRowsInTableView
  # 
  #  Returns the number of records in the table.
  #  This must be implemented by whatever class
  #  acts as the data source for the NSTableView
  #  class.
  ###
  def numberOfRowsInTableView(table)
  	if @current_tasks
  	  @current_tasks.size
  	else
  	  0
	  end
  end

  ###
  # tableView_objectValueForTableColumn_row
  # 
  #  Returns the value corresponding to the cell
  #  (row and column intersection) the user has
  #  currently selected. This must be
  #  implemented by whatever class acts as the
  #  data source for the NSTableView class.
  ###
  def tableView_objectValueForTableColumn_row(table, column, row)
    case column.identifier
    when "check"
      @current_tasks[row].chunks.first.completed.size > 0 ? true : false
    when "prio"
      @current_tasks[row].chunks.first.priority.to_i
    when "name"
      @current_tasks[row].name
    when "duedate"
      @current_tasks[row].chunks.first.due
    end
  end

end

class OfflineTask
  
  attr_accessor :chunks
  attr_accessor :name
  
  def initialize(name, chunks)
    @name = name
    @chunks = chunks
  end
  
end

class OfflineChunk
  
  attr_accessor :completed
  attr_accessor :priority
  attr_accessor :due
  
  def initialize(completed, priority, due)
    @completed = completed
    @priority = priority
    @due = due
  end
  
end