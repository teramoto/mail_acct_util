#!/usr/local/bin/ruby 

require 'csv' 

File.foreach(ARGV[0]) do |line|
# ","2014-04-14 21:21:23 +0900","
#  if /\d{4}-\d{2}\d{2} \d{2}:\d{2}:\d{2} [+-]\d{4}/ =~ line then 
  if /\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} [+-]\d{4}/ =~ line then 
    puts $` + $'
#    puts $' 
  else 
    puts line
  end 
end


