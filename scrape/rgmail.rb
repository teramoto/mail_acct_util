#!/usr/local/bin/ruby 

# encoding : utf-8 
require 'optparse'
require './popchecks.rb'
require './ldaputil.rb'
require './actchkl_sub.rb' 
require 'mail'
require 'nkf'
require 'csv' 
require 'logger'
require 'tracer' 
require 'byebug' 

#
# global arrays for handling domains
#
## report addresses 

### ",yasu@ray.co.jp,d-furuya@ray.co.jp"  ## always get report. 
## main start

Encoding.default_internal = "UTF-8" 

 
puts "$mailtest: #{$mailtest}" if $deb 
# $resend = true
# $mailtest = false 
# $supress = false


# setup server spec parameters.... 
class RGServerSpec
  attr_accessor :popserver, :smtpserver
  @comide = [[ "miyazawa@ray.co.jp", "iwatani@ray.co.jp" ], ["y-kaneda@ray.co.jp", "s-yoshikai@ray.co.jp", "y-usui@ray.co.jp" ] ]
  @visual = [ "n-abe@ray.co.jp","t-hagiwa@ray.co.jp","y-fukuna@ray.co.jp","a-miwa@ray.co.jp" ]
  @event = [ "t-hayakawa@ray.co.jp","m-konno@ray.co.jp" ]
  @event2 = [ "d-endo@ray.co.jp", "s-ito@ray.co.jp", "t-hayakawa@ray.co.jp" ]
  @div = { "event kansai" => "yone@ray.co.jp,h-kagura@ray.co.jp"} 
  $logpath = "actchk.log" 
  def initialize(email)
    bb = email.split('@')
    p bb if $deb 
    if bb == nil || bb.size == 1 || bb.size > 2  then  # check if email is valid
      p bb if $deb
      STDERR.puts "#{email} is invalid." if $deb
      exit(-1)
    end
   #byebug
    puts "bb.size==1" if $deb
    @uid = bb[0]  # $account
    @domain = bb[1] 
    @luid = bb[0] + "@" + @domain 
    case @domain 
    when "ray.co.jp"   # used to be smtp.ray.co.jp , "plays.co.jp", "digisite.co.jp", "wbc-dvd.com", "tera.nu"  ]
      @popserver = 'mail01.bizmail2.com' 
      @smtpserver = @popserver 
      @uid  = @luid
      @email = email
      @popserver = "mail01.bizmail2.com" 
      @smtpserver  = @popserver
      @ldap = "ldap.ray.co.jp" 
      @popdesc = { "pop3s(SSLを使用)" => "995" }
      @imapdesc = { "imaps(SSLを使用)" => "993" }
      @smtpdesc  = { "smtps(SSLを使用)" => "465"  }
      @smtpAuth =  [  "plain", "login" ] 
      @webmail  = "https://mail01.bizmail2.com" # webmail url
      @webmailm = "https://mail01.bizmail2.com/mb" #mobilde webmail url 
      @webmailsp = "" 

    # handled by sakura server www16276uf.sakura.ne.jp ( sk1.ray.co.jp)
    when "ss.ray.co.jp" , "nissayseminar.jp", "nissayspeech.jp", "mcray.jp", "lic.prent.jp", "nissay-miraifes.jp"
      #  $host = "www16276uf.sakura.ne.jp"
      @popserver = 'sk1.ray.co.jp'
      @smtpserver = @popserver 
      @uid = email 
      @email = email
      @webmail = "https://www16276.sakura.ne.jp"
      @webmail = "http://sk1.ray.co.jp"
      @webmailm = "http://sk1.ray.co.jp"
      @webmailsp = "" 
      @ldap = "ldap2.ray.co.jp" 
 
    when  "wes.co.jp"  # web areana
      @popserver = "dc13.etius.jp" # "wes.co.jp" 
      @smtpserver = @popserver
      @uid = bb[0]
      @email = email 
      @ldap = "file" 
      @passfile = $wespassfile 
      @email = $uid + $domain 
      @webmail = ""
      @webmailm = "" 

#byebug 
      @pop = {"pop3" => "110", "pop3s(SSLを使用)" => "995" }
      @imap = { "imap" => "143", "imaps(SSLを使用)" => "993" }
      # puts '-' * 40 
#  byebug
      @smtpSend  = {"smtp" => "25" , "smtp" => "587", "smtps(SSLを使用)" => "465"  }
      @smtpAuth =  [ "PLAIN", "LOGIN" ] 
      @webmail   = "http://wes.co.jp/WEBMAIL/dnwml3/dnwmljs.cgi"  
      @webmailsp = "http://wes.co.jp/WEBMAIL/dnwmljs.cgi" 
      @webmailmb = "http://wes.co.jp/WEBMAIL/dnmwml3/dnmwml.cgi" 
      @manual = "http://it.ray.co.jp/html/mail" 
      @manualm = "http://web.arena.ne.jp/support/suitex/manual/mail/instruction.html" 
      @ldap = "file"
      @passfile = "/var/www/html/foundation-4/admin/scrape/wespass.csv" 
    when "tc-max.co.jp"  # kagoya

      puts "#{bb[1]}: $wdomain" if $deb  
      # byebug 
      @popserver  = "mas14.kagoya.net"
      @smtpserver = "smtp.kagoya.net" 
      @pop = {"pop3" => "110"}
      @imap = { "imap" => "143"  }
      @smtpSend  = { "smtp" => "587"   }

      if $deb then 
        puts '-' * 40 
        $pop.each do |key,val|
          print "#{key} => #{val}, " 
        end 
#       byebug 
        puts 
        $imap.each do |key,val|
          print "#{key} => #{val}, " 
        end 
        puts
      end 
#     byebug
      @uid = "tcm." + bb[0] 
      @email = email
      @webmail   = "https://activemail.kagoya.com/"  
      @webmailsp = "https://activemail.kagoya.com/am_bin/slogin?userid=#{$uid}" 
      @webmailm  = "https://activemail.kagoya.com/am_bin/mlogin?userid=#{$uid}" 
      @manual = "http://it.ray.co.jp/html/mail" 
      @manualm = "http://support.kagoya.jp/manual/startup/mail_account_settings.html#mailclient" 
      @ldap = "file"
      @passfile = "/var/www/html/foundation-4/admin/scrape/tcmpass.csv"
    when  "digisite.co.jp", "plays.co.jp", "wbc-dvd.com", "tera.nu"  # smtp.ray.co.jp

    when  "c.ray.co.jp" # sakura hosting
      @popserver = "c.ray.co.jp"
      @pop = {"pop3" => "110" }
      @imap = { "imap" => "143" }
      puts '-' * 40 if $deb
#  byebug
      @smtpserver = "c.ray.co.jp" 
      @smtpSend  = {"smtp" => "25" , "smtp" => "587"}
      @smtpAuth =  [ "PLAIN", "LOGIN" ] 
      @uid =  email 
      @email = email
      @webmail   = "https://secure.sakura.ad.jp/rscontrol/?webmail=1"
      @webmailsp = ""
      @webmailmb = ""
      @manual = "http://it.ray.co.jp/html/mail" 
      @manualm = "https://help.sakura.ad.jp/app/answers/detail/a_id/2236"
      @ldap = "file"
      @passfile = "/var/www/html/foundation-4/admin/scrape/craymail.txt"

    else
      STDERR.puts "Domain #{bb[1]} is not supported."
      STDERR.puts "uid = #{bb[0]}"
      STDERR.puts "not match. exit" 
      exit(-1)
    end 
  end
end
byebug
if ARGV[0]&.length > 1 then 
  email = ARGV[0] 
else 
  email = "ken@ray.co.jp"   
end
t = RGServerSpec.new (email)
pp t 

