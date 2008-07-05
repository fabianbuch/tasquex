#
#  rb_main.rb
#  tasqueX
#
#  Created by Fabian Buch on 02.07.08.
#  Copyright (c) 2008 Fabian Buch. All rights reserved.
#

require 'osx/cocoa'

def rb_main_init
  #path = OSX::NSBundle.mainBundle.resourcePath.fileSystemRepresentation
  #rbfiles = Dir.entries(path).select {|x| /\.rb\z/ =~ x}
  #rbfiles -= [ File.basename(__FILE__) ]
  #rbfiles.each do |path|
  #  require( File.basename(path) )
  #end
  require File.basename("controller.rb")
end

if $0 == __FILE__ then
  rb_main_init
  OSX.NSApplicationMain(0, nil)
end
