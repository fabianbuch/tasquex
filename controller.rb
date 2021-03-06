#
#  controller.rb
#  tasqueX
#
#  Created by Fabian Buch on 02.07.08.
#  Copyright (c) 2008 Fabian Buch. All rights reserved.
#

require 'osx/cocoa'
require 'date'

class Controller < OSX::NSObject
  include OSX

  ib_outlet :mainWindow, :authWindow, :prefsWindow
  ib_outlet :tableTasks
  
  ib_outlet :inputNewTask, :buttonLists, :buttonAddTask, :buttonAuth
  ib_outlet :buttonComplete
  ib_outlet :buttonSpinner
  ib_outlet :prefsButtonAuthCache, :prefsButtonStore
  
  ib_outlet :lists
  
  def initialize
    setupDefaults
  end
  
  def setupDefaults
      # load the default values for the user defaults
      userDefaultsValuesPath = NSBundle.mainBundle.pathForResource_ofType(
        "UserDefaults", "plist"
      )
      userDefaultsValuesDict = NSDictionary.dictionaryWithContentsOfFile(
        userDefaultsValuesPath
      )

      # set them in the standard user defaults
      NSUserDefaults.standardUserDefaults.registerDefaults(
        userDefaultsValuesDict
      )

      # Set the initial values in the shared user defaults controller
      NSUserDefaultsController.sharedUserDefaultsController.setInitialValues(
        'authCache' => false,
        'store' => 'Dummy Backend',
        'rtmtoken' => ''
      )
  end
  
  # like initialized, but will be called after Nib is loaded
  def awakeFromNib
    store = NSUserDefaultsController.sharedUserDefaultsController.values.valueForKey('store').to_s
    
    case store
    when 'Remember The Milk'
      @store = TasqueX::RtmStore.new
    when 'Dummy Backend'
      @store = TasqueX::DummyStore.new
    when 'SQLite Backend'
      raise "ERROR: SQLite-Backend not yet implemented!"
    else # use 'Dummy Backend'
      @store = TasqueX::DummyStore.new
    end
    
  end
  
  def authenticate
    start_spinning
    
    unless @store.authenticated?
      # open window sheet for authentication
      openAuthSheet
    else
      # show hidden elements
      hide_or_show_various_elements
      
      # init data
      init_lists
      init_tasks
    end
    
    stop_spinning
  end
  
  def start_spinning
    @buttonSpinner.setHidden(false)
    @buttonSpinner.startAnimation(self)
  end
  
  def stop_spinning
    @buttonSpinner.stopAnimation(self)
    @buttonSpinner.setHidden(true)
  end
  
  def openAuthSheet
    
    # open a modal window
      NSApp.beginSheet_modalForWindow_modalDelegate_didEndSelector_contextInfo(@authWindow, @mainWindow, self, :sheetDidEnd_returnCode_contextInfo, nil)
    
    # authenticate
    @store.authenticate
  end
  
  def sheetDidEnd_returnCode_contextInfo(sheet, code, context)
    sheet.orderOut(nil)
  end

  def authNextButton
    start_spinning
    
    if @store.authenticated?
    
      # close modal window
      NSApp.endSheet_returnCode(@authWindow, 0)
      
      # show hidden elements
      hide_or_show_various_elements
      
      # init data
      init_lists
      init_tasks
      
    else
      
      @store.authenticate
      
    end
    
    stop_spinning
  end
  
  def hide_or_show_various_elements
    @buttonAuth.setHidden(true)
    @tableTasks.setHidden(false)
    @inputNewTask.setHidden(false)
    @buttonLists.setHidden(false)
    @buttonAddTask.setHidden(false)
    @buttonComplete.setHidden(false)
  end
  
  def init_lists
    start_spinning
    
    lists = @store.all_lists
    lists.each do |list|
      @lists.addItemWithTitle(list.name)
      @lists.lastItem.setTag(list.id)
    end
    
    stop_spinning
  end
  
  def init_tasks
    start_spinning
    
    list_id = @lists.selectedItem.tag.to_i==0 ? nil : @lists.selectedItem.tag
    @current_tasks = @store.all_incomplete_tasks(list_id).sort
    
    stop_spinning
    @tableTasks.reloadData
  end
  
  def switchList
    menu_item = @lists.selectedItem
    @lists.selectItem(menu_item)
    
    start_spinning
    
    if menu_item.tag.to_i == 0
      # select all lists
      @current_tasks = @store.all_incomplete_tasks.sort
    else
      # only this list
      @current_tasks = @store.all_incomplete_tasks(menu_item.tag).sort
    end
    
    stop_spinning
    
    @tableTasks.reloadData
  end
  
  def toggleShowComplete
    list_id = @lists.selectedItem.tag.to_i==0 ? nil : @lists.selectedItem.tag
    
    start_spinning
    
    if @buttonComplete.selectedSegment == 1
      @current_tasks = @store.all_incomplete_tasks(list_id).sort
    elsif @buttonComplete.selectedSegment == 2
      @current_tasks = @store.all_complete_tasks(list_id).sort
    else
      @current_tasks = @store.all_tasks_in_list(list_id).sort
    end
    
    stop_spinning
    
    @tableTasks.reloadData
  end
  
  def addTask
    if @inputNewTask.stringValue.to_s.size > 0
      
      start_spinning
      
      @store.add_task(@lists.selectedItem.tag, @inputNewTask.stringValue)
      
      stop_spinning
      
      switchList
      toggleShowComplete
    end
  end
  
  def deleteTasks
    start_spinning
    
    @tableTasks.selectedRowIndexes.to_a.each do |i|
      @store.delete_task(@current_tasks[i])
    end
    
    stop_spinning
    
    switchList
    toggleShowComplete
  end

  def openPrefsWindow
    NSApp.beginSheet_modalForWindow_modalDelegate_didEndSelector_contextInfo(@prefsWindow, @mainWindow, self, :sheetDidEnd_returnCode_contextInfo, nil)
  end
  
  def closePrefsWindow
    NSApp.endSheet_returnCode(@prefsWindow, 0)
  end
  
  def tableView_setObjectValue_forTableColumn_row(table, value, column, row)
    case column.identifier
    when "check"
      if "1" == value.to_s # 1 => true (NSCFBoolean)
        @current_tasks[row].completed = Time.now.to_s
      else
        @current_tasks[row].completed = ""
      end
    when "prio"
      @current_tasks[row].priority = value.to_s
    when "name"
      @current_tasks[row].name = value.to_s
    when "duedate"
      @current_tasks[row].due = TasqueX::DateTime.parse(value.to_s)
    end
    
    start_spinning
    
    @store.edit_task(@current_tasks[row])
    
    stop_spinning
    
    @current_tasks.sort!
    @tableTasks.reloadData
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
      @current_tasks[row].completed.to_s.size > 0 ? true : false
    when "prio"
      @current_tasks[row].priority.to_i
    when "name"
      @current_tasks[row].name
    when "duedate"
      completed = @current_tasks[row].completed.to_s.size > 0 ? true : false
      duedate = @current_tasks[row].due
      duedate.kind_of?(TasqueX::DateTime) ? duedate.to_pretty_s : duedate.to_s
    end
  end
  
  # for duedate cell
  def numberOfItemsInComboBoxCell(cell)
    p TasqueX::DateTime.parse(DateTime.now.strftime).class
    TasqueX::DateTime.parse(DateTime.now.strftime).sevendays.size
  end
  
  # for duedate cell
  def comboBoxCell_objectValueForItemAtIndex(cell, index)
    p TasqueX::DateTime.parse(DateTime.now.strftime).sevendays
    TasqueX::DateTime.parse(DateTime.now.strftime).sevendays[index.to_i]
  end

end
