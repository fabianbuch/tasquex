#
#  controller.rb
#  tasqueX
#
#  Created by Fabian Buch on 02.07.08.
#  Copyright (c) 2008 Fabian Buch. All rights reserved.
#

require 'rubygems' # TODO remove and include ext libs into distribution
require 'rtmilk'

require 'osx/cocoa'


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
  
  ib_outlet :newTask
  ib_outlet :lists
  
  API_KEY       = 'f777b4bcbda99484bd823c9c301e6dca'
  SHARED_SECRET = 'f59e95985a21acc1'
  
  # like initialized, but will be called after Nib is loaded
  def awakeFromNib
    # provide APP_KEY and SHARED_SECRET for RTM::API
    RTM::API.init(API_KEY, SHARED_SECRET)
    
    # get frob
    @frob = RTM::Auth::GetFrob.new.invoke
    
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
  
  def authNextButton
    get_token
    if RTM::API.token
      NSApp.endSheet_returnCode(@authWindow, 0)
      
      # TODO move lists elsewhere
      lists = RTM::List.alive_all
      lists.each { |l| @lists.addItemWithTitle(l.name) }
    else
      authInBrowser
    end
  end
  
  def authInBrowser
    # get auth url for read
    url = RTM::API.get_auth_url('read', @frob)
    puts url
    
    `open '#{url}'`
  end
  
  def get_token
    res = RTM::Auth::GetToken.new(@frob).invoke
    token = res[:token]
    RTM::API.token = token
  end
  
  def switchList
    menu_item = @lists.selectedItem
    @lists.selectItem(menu_item)
    
    if menu_item.title.to_s == "All"
      # select all lists
    else
      # only this list
    end
  end
  
  def addTask
    p @newTask.stringValue
  end

  def tableView_setObjectValue_forTableColumn_row(table, value, column, row)
    p value
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
  	2
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
    Time.now.to_s
  end

end
