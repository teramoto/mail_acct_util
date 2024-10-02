#!/usr/local/bin/ruby 

require 'net/pop'
require 'rubygems'
require 'kconv'
#require 'tmail'
require 'mail'
require 'date'
require 'yaml'
require 'term/ansicolor'
include Term::ANSIColor
require 'logger'
require 'time' 
require 'byebug' 

$log = Logger.new('popdel.log')
$log.level= Logger::INFO
print reset;
# expterm = 10*24*60*60 # 45 days to hold
expterm = 20*24*60*60 # 31  days to hold
expterm = 24 * 60 * 60 * 365 * 20 # 20 year is enough?   
$today = Time.now
#today = Time.local(2012, 1, 6, 12,12,12)
$day2 = $today - expterm
#$day2 = Time.local($today.year, $today.month-expterm, $today.day,$today.hour,$today.min,$today.sec)
p $today.day
p $day2
#exit  ## for check 
# $deb = true

def popcheck(user, domain, passwd)
   $log.info("#{user}:#{domain}") 
   del=0
   newest = $day2
   oldest = $today
   mfrom =""
   mto = "" 
   msubject=""  
   tm = nil 
  Net::POP3.enable_ssl
  Net::POP3.start(domain, 995, user,passwd) do |pop| 
    pop.enable_ssl 
# Net::POP.start('tc-max.co.jp', 110, 'ken','Ray12345') do |pop| 
    p pop.mails if $deb  
    if pop.mails.empty?
      $stderr.puts 'no mail'
      return false;
    else 
     cnt = 0 
      dd = nil
      pop.each_mail do |m| # s.each do |m|
        puts "m.headers=#{m.header}" if $deb 
        rmes = m.header.split("\r\n")
#        byebug 
        xx = nil
        cnt = 0 
        rmes.each {|stw|
          st = stw.lstrip
          if (st.start_with?("Date:")) then
            dd = st.slice(5,st.length - (5))  
            tm = Time.parse(dd)
          elsif ( st.start_with?("From:"))  then 
            mfrom = st 
          elsif ( st.start_with?("To:"))  then 
            mto = st 
          elsif ( st.start_with?("Subject:"))  then 
            msubject = st 
          end 
          cnt+= 1
        }
#        mail = Mail.new(m)   
#        puts mail.header 
#        puts mail.date 
#        byebug
        puts "#{cnt}:#{dd}" 
        if dd != nil then 
#        m.pop do |str|
#          puts str
#        end 
#        byebug
#        mail = TMail::Mail.parse(m.pop)
          dd = nil 
          begin 
            mday = tm
      
            diff = mday - $day2
            # puts diff
            if (mday < oldest ) then 
              oldest = mday
            else 
              if ( mday > newest) then
                newest = mday
              end 
            end
            if (diff < 0)  then
              tmst = tm.strftime("%Y:%M:%D")
              print "#{diff} #{tmst} #{mfrom}:[#{msubject.toutf8[0,30]}] \n".red, reset
              m.delete
              del +=1 
              $log.info("#{diff} #{tmst} #{mfrom}:[#{msubject.toutf8[0,30]}] ")
#            else 
#              puts( "#{diff} #{mail.date} #{mail.from}:[#{mail.subject.toutf8[0,30]}]  ").reset
            end
            tm = nil
          rescue => exc
            p exc
            tm = nil 
            $log.error("#{m} #{exc}:#{msubject.toutf8}") #  #{m.body.toutf8}")
          end
        end 
      end 
    end
  end 
#       a=gets
  $log.info("Oldest #{oldest.to_s} , Newest #{newest.to_s}")
  $log.info("#{del} messages deleted.")
  return true
end
## main ---
#exit
#.divmod(24*60*60)
# passfile = open("tcmpass.csv") 
user = ARGV[0] 
server= ARGV[1] 
passwd = ARGV[2] 
popcheck(user, server, passwd)
exit(0) 

passfile = open("TCMail1.csv") 
passfile.each do |line|
  body = line.chomp.split(",")
  if body[0] != nil then 
    p body
    passwd = body[0]
    b2 = body[1].split("@")
    user = b2[0]
    domain = b2[1]
    print "#{passwd} #{user} #{domain}"
    begin 
      popcheck(user, domain, passwd)
    rescue => exp2
      $log.error("Error: #{user} #{domain} #{passwd}") 
    end
  end 
end
passfile.close

