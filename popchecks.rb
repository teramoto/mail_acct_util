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

def smtpcheck(user, server, passwd, to_addr, comm, debug , domain)
  log = Logger.new('popcheck.log')
  log.level= Logger::INFO
  ret = true
  stat = 0
  case comm
  when 'r' 
    puts "SMTP RCPT Check mode"  if debug 
    begin 
      smtp = Net::SMTP.new(server, 25) 
      smtp.set_debug_output $stderr if debug
      smtp.start('smtp.ray.co.jp' )  
      smtp.mailfrom('ken@digisite.jp') 
      smtp.rcptto(to_addr)
    rescue => exsm
       stat = 1
       puts exsm 
       ret = true 
    end 
    if stat == 1 then 
       puts "RCPT Error" if debug  
       ret = true 
    else 
       puts "RCPT OK" if debug 
       ret = false
    end
  when 's' 
    puts "SMTP Delivery Check mode"  if debug 
    begin 
      smtp = Net::SMTP.new(server, 25) 
      smtp.set_debug_output $stderr if debug 
      smtp.start(server )  
      smtp.send_message  'Test Message', 'ken@ray.co.jp', to_addr 
    rescue => exsm
       stat = 1
       puts exsm 
       ret = true 
    end 
    if stat == 1 then 
       puts "Delivery Error" if debug  
       ret = true 
    else 
       puts "Delivery succeed." if debug 
       ret = false
    end
  when 'a', 'al','ap','ac' 
    puts "SMTP Auth Check mode" if debug
    stat = 0 
    begin 
      smtp = Net::SMTP.new(server, 25) 
      smtp.set_debug_output $stderr if debug
      case comm
      when 'a','al'
        smtp.start(domain, user , passwd,  :login ) # :login :plain :cram_md5  
      when 'ap'
        smtp.start(domain, user , passwd,  :plain ) # :login :plain :cram_md5  
      when 'ac'
        smtp.start(domain, user , passwd,  :cram_md5 ) # :login :plain :cram_md5  
      end 
      smtp.send_message  'Test Message', "#{user}@#{domain}", to_addr
    rescue => exsm
       stat = 1
       puts exsm if debug 
       ret = true
    end
    if stat == 1 then 
       puts "Send Error" if debug 
       ret = true 
    else 
       puts "send mail succeed."
       ret = false
    end
  end 
  return ret 
end

def popcheck(user, server, passwd, comm )
  log = Logger.new('popcheck.log')
  log.level= Logger::INFO
  if comm == "d" then
    fdebug = true 
  else 
    fdebug = false
  end 
#   return false 
  ret = true
  puts "POP Server Check mode" if fdebug  
  log.info("#{user}:#{server}") 
  del=0
  newest = $day2
  oldest = $today
  puts "Starting pop operation..."  if fdebug 
  pop = Net::POP.new(server,110) 
  pop.set_debug_output $stderr if fdebug 
  begin 
    pp = pop.start( user,passwd)
    if pp != nil  then  
       $stderr.puts "POP Login Success:#{user}" if fdebug  
       return false
     else
       return true
     end 
  rescue => ex 
    p ex 
    return true
  end
end

def newmain 

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
 

# print "#{$passwd} #{$user} #{$server}\n"
  begin
    case $comm
    when 's' # smtp send test to server
      $res = smtpcheck($user, $server, $passwd, $comm)
    when 'a' # smtp auth test 
      $res = smtpcheck($user, $server, $passwd,$to_addr, $comm)
    else  
      $res = popcheck($user, $server, $passwd, $comm)
    end 
  rescue => exp2
    $log.error("Error: #{$user} #{$server} #{$passwd}:#{exp2}") 
  end
 exit(true)
end 
