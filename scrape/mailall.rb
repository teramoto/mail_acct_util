#!/usr/local/bin/ruby 

require 'logger' 
require 'optparse'
require './ldaputil' 

p ARGV 
$opt = OptionParser.new
$debug = false 
$mailonly = false
$opt.on('-d', 'debug mode ') {|v| $debug = true }
$opt.on('-m', 'mail only -- no action on directory, only send finish report via email to each user.' ) {|v| $mailonly = true} 
$opt.on('-h VAL', 'Add header message.' ) {|v| $head = v } 
argv = $opt.parse!(ARGV)
p ARGV 
if argv.length == 1 then 
  fname = argv[0]
else 
  fname = "emlist.txt" 
end 
$log = Logger.new("mailreport.log")
$log.level = Logger::INFO
puts "-m #{$mailonly} -d #{$debug} ARGV.length #{argv.length}" 
puts argv[0] 
file =open(fname) 
  
  file.each do |line|
    bb = line.chomp.split(",")
    puts bb[0] , bb[1] 
    if bb[0].size > 0 then 
      puts bb[0] , bb[1] 
      # get data from desknet's db 
      if $head != nil then 
        hmes = "-h #{$head}" 
      else 
        hmes = ""
      end  
      if valid_email_address?(bb[0]) then
        b2 = bb[0].split("@")
        raymail = b2[0] + "@ray.co.jp"  
        puts "/usr/local/bin/ruby actchkl2.rb #{hmes} -r -t #{raymail}  #{bb[0]}" if ($mailonly == false || $debug == false )
        `/usr/local/bin/ruby actchkl2.rb #{hmes} -r -t #{raymail}  #{bb[0]}` if ($mailonly == false || $debug == false )
        $log.info( bb[0]) 
      else 
        puts "bad email:#{bb[0]}"
        $log.info( bb[0]) 
      end 
    end 
  end

