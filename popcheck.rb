#!/usr/local/bin/ruby 

require 'net/pop'
require 'net/smtp'
require 'rubygems'
#require 'kconv'
# require 'tmail'
require 'date'
require 'yaml'
# require 'term/ansicolor'
# include Term::ANSIColor
require 'logger'

$log = Logger.new('popcheck.log')
$log.level= Logger::INFO
# print reset;
expterm = 30*24*60*60 # 45 days to hold
$today = Time.now
#today = Time.local(2012, 1, 6, 12,12,12)
$day2 = $today - expterm
#$day2 = Time.local($today.year, $today.month-expterm, $today.day,$today.hour,$today.min,$today.sec)
p $today.day
p $day2
#exit  ## for check 
$DEBUG = nil 

def smtpcheck(user, server, passwd, to_addr, comm, port)
  stat = 0
  case comm
  when 's' 
    puts "SMTP Delivery Check mode" 
    begin 
      smtp = Net::SMTP.new(server, port) 
      smtp.set_debug_output $stderr if $DEBUG 
      smtp.start(server )  
      smtp.send_message  'Test Message', 'ken@ray.co.jp', passwd
    rescue => exsm
       stat = 1
       puts exsm 
    end 
    if stat == 1 then 
       puts "Delivery Error" 
    else 
       puts "Delivery Suceed."
    end
    smtp.finish
    puts "SMTP Closed." 
  when 'a' 
    puts "SMTP Auth Check mode" 
    stat = 0 
    begin 
      smtp = Net::SMTP.new(server, port) 
      smtp.set_debug_output $stderr if $DEBUG 
      smtp.start(server, user , passwd,  :login ) # :login :plain :cram_md5  
      smtp.send_message  'Test Message', "#{user}@ray.co.jp", to_addr
    rescue => exsm
       stat = 1
       puts exsm 
    end
    if stat == 1 then 
       puts "Send Error" 
    else 
       puts "send mail  Suceed."
    end
    smtp.finish
    puts "SMTP Closed." 
  end    
end

def popcheck(user, server, passwd, comm )
   puts "POP Server Check mode" 
   $log.info("#{user}:#{server}") 
   del=0
   newest = $day2
   oldest = $today
   puts "Starting pop operation..."  
   pop = Net::POP.new(server,110) 
   pop.set_debug_output $stderr if $DEBUG
   pop.start( user,passwd)do |pop| 
# Net::POP.start('tc-max.co.jp', 110, 'ken','Ray12345') do |pop| 
      $stderr.puts "POP Login Success:#{user}" 
      # puts "POP Login Success:#{user}" 
      nb = pop.n_bytes
      nm = pop.n_mails 
      puts "#{nm} mails,  #{nb} bytes" # if $DEBUG  
      return true  
      if pop.mails.empty?
         $stderr.puts 'no mail'
         return false;
      else 
         pop.mails.each do |m|
            if (comm == "del") then 
              m.delete
            else      
              mail = TMail::Mail.parse(m.pop)
	      begin 
                mday = mail.date 
                diff = mday - $day2
 	       # puts diff
 
              rescue => exc
                 p exc
                 $log.error("#{mail.date} #{mail.subject.toutf8} #{mail.body.toutf8}")
              else
                 if (mday < oldest ) then 
                     oldest = mday
                 else 
                    if ( mday > newest) then
                       newest = mday
 
                    end  
                 end
                 if (diff < 0)  then
	            print "#{diff} #{mail.date} #{mail.from}:[#{mail.subject.toutf8[0,30]}] \n".red, reset
                    m.delete
                    del +=1 
	            $log.info("#{diff} #{mail.date} #{mail.from}:[#{mail.subject.toutf8[0,30]}] ")
 
                 else 
	            puts( "#{diff} #{mail.date} #{mail.from}:[#{mail.subject.toutf8[0,30]}]  ").reset
	         end
              end 
            end
         end
#         a=gets
      end
   end
   $log.info("Oldest #{oldest.to_s} , Newest #{newest.to_s}")
   $log.info("#{del} messages deleted.")
   return true
end
## main ---
#exit
#.divmod(24*60*60)

puts "#{ARGV.size} args "  
if ARGV.size< 3 then 
   puts "need user, server, passwd"
   exit
end
$argc = 0 
$comm = 'p' 
(0..ARGV.size-1).each { | num |
  puts "#{num}:#{ARGV[num]}" if $DEBUG 
  case ARGV[num] 
  when '-s' 
    $comm = 's'
  when '-a' 
    $comm = 'a'
  when '-d','-D' 
    $DEBUG = 1 
  else
    dd = ARGV[num]
    case $argc 
    when 0 
      $user = dd 
      $argc += 1 
    when 1 
      $server = dd
      $argc += 1 
    when 2 
      $passwd = dd
      $argc += 1 
    when 3 
      $to_addr = dd
      $argc += 1 
    else 
      puts "Parameter Error!#{dd}:#{$argc}" 
      exit -1
    end 
  end
}
 

print "#{$passwd} #{$user} #{$server}\n"
  begin
    case $comm
    when 's' # smtp send test to server
      smtpcheck($user, $server, $passwd, $comm)
    when 'a' # smtp auth test 
      smtpcheck($user, $server, $passwd,$to_addr, $comm)
    else  
      popcheck($user, $server, $passwd, $comm)
  end
  rescue => exp2
    $log.error("Error: #{$user} #{$server} #{$passwd}:#{exp2}") 
  end

