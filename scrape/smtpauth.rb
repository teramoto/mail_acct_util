#!/usr/local/bin/ruby 
# encoding : utf-8 
require 'optparse'
require './popchecks.rb'
require './ldaputil.rb'
require 'mail'
require 'nkf'

$tdomain = [ "ray.co.jp", "plays.co.jp", "digisite.co.jp","wes.co.jp","tc-max.co.jp","nissayseminar.jp" ]
$adminaddr = ""   # ,yasu@ray.co.jp,d-furuya@ray.co.jp"  ## always get report. 

## main start
opt = OptionParser.new
OPTS = {}
Version = '0.1' 
$cc = Array.new
$to = Array.new 
$gp = Array.new
$adm = Array.new 
passwd = "" 
name = "" 
deb = false 
authmode = 0 
puts "e-mail , shain # " 
opt.on('-s VAL', 'smtp server to send commands.') {|v| $smtpserver = v }
opt.on('-u VAL', 'login id for smtp server.') {|v| $uid = v }
opt.on('-c VAL', 'cc: address to send report mail') {|v| $cc.push(v) }
opt.on('-t VAL', 'to: address to send report mail') {|v| $to.push(v) }
opt.on('-g VAL', 'group address belonged. ') {|v| $gp.push(v) }
opt.on('-m VAL', 'additional e-mail address') { |v| $adm.push(v) } 
opt.on('-n VAL', 'supply name manually' ) { |v| name = v }
opt.on('-p VAL', 'supply password manually') { |v| passwd = v } 
opt.on('-d', 'debug mode ') { deb = true }
opt.on('-l VAL', 'which auth to check   ') { |v| authmode = v }


p ARGV
rr = opt.parse!(ARGV)
p rr
puts "ARGV"
p ARGV 
puts "OPTS"
p OPTS 
$account = ARGV[0] 
if $account == nil || $account.length ==0 then 
  puts "Acconut is invalid.(#{$account})" 
  exit -1
end
$shain = ARGV[1]
if ((deb == true) ||( $resend == true )) then 
  $adimnaddr =""  # don't send to admin, when debug  
end 
  
bb = $account.split('@')
p bb
puts "bb.size = #{bb.size}" 
if bb == nil then 
  p bb
  puts "#{$account} is invalid."
  exit -1
elsif bb.size == 1 then
  if ($uid == nil) || ($uid.length ==0) then 
    $uid = $account
  end 
  $domain = "ray.co.jp" 
elsif $tdomain.index(bb[1]) then
  if ($uid == nil) || ($uid.length ==0) then 
    $uid = $account 
  end 
  $domain = bb[1]
elsif ($uid == nil || $uid.length == 0 ) then 
   puts "uid bot supplied." 
   exit -1 
else  
#  puts "Domain #{bb[1]} is not supported."
  $domain = bb[1]
  
  puts "domain:#{$domain}: uid:#{$uid}"
end 

puts "Domain #{$domain}."
puts "uid = #{$uid}" 

## check pop behavior  
report = Array.new
pass = 0
if ($domain == 'wes.co.jp') then  
  email = $uid + "@"+ $domain
else 
  email = $uid 
end
  puts "email~#{email}" 
  if (passwd == "" ) then 
    if (passwd = getpass(email)) == true then 
      puts "Cannot get password."
      exit -1
    end
  end

  puts("pass:#{passwd},name:#{name}")
  p $smtpserver
  ldap = 'ldap.ray.co.jp'
  if ($smtpserver != nil) && ($smtpserver.length > 3)  then
    smtpsrv = $smtpserver 
  else
    if $domain == "wes.co.jp" then 
      popsrv = "wes.co.jp" 
      smtpsrv = "wes.co.jp" 
    elsif $domain == "ray.co.jp" then 
      popsrv = "mail01.bizmail2.com" 
      smtpsrv = "mail01.bizmail2.com"
    elsif $domain == "tc-max.co.jp" then 
      popsrv = "tc-max.co.jp" 
      smtpsrv = "smtp.tc-max.co.jp" 
    elsif $domain == "nissayseminar.jp" then 
      $uid = $uid + "@" + $domain 
      popsrv = "pop.nissayseminar.jp" 
      smtpsrv = "smtp.nissayseminar.jp" 
      ldap = "wm2.ray.co.jp" 
    end
  end  
  puts ("Server = #{smtpsrv} ")
  
  puts "Domain #{$domain}."
  puts "uid = #{$uid}" 
  puts "paswd = #{passwd}" 
  if (authmode == 0 ) then
    authmode = 0b111
  end
  if (authmode.to_i & 0b1) then
## check smtp auth
    res = smtpcheck( $uid , smtpsrv, passwd , 'ken@znet.tokyo_' , 'al', deb, $domain, ldap )
    if res then 
      puts  "#{$uid}:AUTH送信テスト失敗.#{Time.now}"
    else
      pass +=1 
      puts  "#{$uid}:AUTH送信テスト成功.#{Time.now}"
    end
  end
  if (authmode.to_i & 2) then 
    res = smtpcheck( $uid , smtpsrv, passwd , 'ken@znet.tokyo_' , 'ap', deb, $domain , ldap)
    if res then 
      puts  "#{$uid}:AUTH送信テスト失敗.#{Time.now}"
    else
      pass +=1 
      puts  "#{$uid}:AUTH送信テスト成功.#{Time.now}"
    end
  end
  if (authmode.to_i & 4) then 
    res = smtpcheck( $uid , smtpsrv, passwd , 'ken@znet.tokyo_' , 'ac', deb, $domain ,ldap )
    if res then 
      puts  "#{$uid}:AUTH送信テスト失敗.#{Time.now}"
    else
      pass +=1 
      puts  "#{$uid}:AUTH送信テスト成功.#{Time.now}"
    end
  end 
  p report
  $slist = Array.new  
  $slist.push("e-mail")
  ## additional e-mail ??

