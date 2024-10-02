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
require 'erb' 

$profbase = "/var/www/html/foundation-4/html/"

# option for mice -ijla -c hideo@ray.co.jp -c d-saito@ray.co.jp -c k-muto@ray.co.jp

#
# global arrays for handling domains
#
#  handled by smtp.ray.co.jp , directory by ldap.ray.co.jp
$tdomain = [ "ray.co.jp","c.ray.co.jp" ] # , "plays.co.jp", "digisite.co.jp", "wbc-dvd.com", "tera.nu"  ]
# handled by sakura server www16276uf.sakura.ne.jp ( sk1.ray.co.jp) 
$udomain = [ "ss.ray.co.jp" , "nissayseminar.jp", "nissayspeech.jp", "mcray.jp", "lic.prent.jp", "nissay-miraifes.jp" ]
$vdomain = [ "wes.co.jp" ]  # web areana
$wdomain = [ "tc-max.co.jp" ]  # kagoya
$cdomain = [ "digisite.co.jp", "plays.co.jp", "wbc-dvd.com", "tera.nu"  ] # smtp.ray.co.jp 
$xdomain = [ "c.ray.co.jp" ] # sakura hosting  -> conoha 
$tcmpassfile  = "/var/www/html/foundation-4/admin/scrape/tcmpass.csv"
$craypassfile = "/var/www/html/foundation-4/admin/scrape/conoha_mail.csv"
$wespassfile  = "/var/www/html/foundation-4/admin/scrape/wespass.csv" 
$div = { "event kansai" => "yone@ray.co.jp,h-kagura@ray.co.jp"} 
$logpath = "actchk.log" 
## report addresses 
$comide = [[ "miyazawa@ray.co.jp"  ], ["y-kaneda@ray.co.jp", "s-yoshikai@ray.co.jp"] ]
$comidedd = [ "y-usui@ray.co.jp", "hayashi@ray.co.jp"] 
$mcray = [ "n-abe@ray.co.jp","t-hagiwa@ray.co.jp","y-fukuna@ray.co.jp","a-miwa@ray.co.jp" ]
$mcraye1 = [ "t-fukuna@ray.co.jp","t-hagiwa@ray.co.jp","s-akasaka@ray.co.jp" ] # 第一営業第一 
$mcrays = [ "n-abe@ray.co.jp","t-hagiwa@ray.co.jp","r-takasuka@ray.co.jp" ]
$mcrayflame = [ "n-abe@ray.co.jp", "t-hagiwa@ray.co.jp","nakagami@ray.co.jp" ]
$event = [ "t-hayakawa@ray.co.jp","m-konno@ray.co.jp" ]
$eventaud = [ "t-hayakawa@ray.co.jp","m-nakai@ray.co.jp" ]
$eventosaka = [ "yone@ray.co.jp", "h-kagura@ray.co.jp" ,"t-tani@ray.co.jp" ] 
$mice = [ "d-saito@ray.co.jp" ]
$admin = [ "w-makita@ray.co.jp" ]
$credenm =  [ "t-niijima@ray.co.jp", "t-shiina@ray.co.jp", "k-iwata@ray.co.jp" ]
$credetc = [ "t-niijima@ray.co.jp", "nakamura@ray.co.jp","k-ishida@ray.co.jp" ] 
$credeosaka = [ "a-sakata@ray.co.jp","m-aburada@ray.co.jp"]
# p $eventaud 
SV = "conoha" 
#$debugdebug = true 
$debugdebug = false 
unless $debugdebug then 
  $adminary = [ "d-furuya@ray.co.jp","yosuke-ito@ray.co.jp","ict@ray.co.jp" ]
else 
  $adminary = [ "mtest@ray.co.jp", "ken_root@ray.co.jp" ]
end 
### ",yasu@ray.co.jp,d-furuya@ray.co.jp"  ## always get report. 
## main start

Encoding.default_internal = "UTF-8" 
# byebug 
opt = OptionParser.new
OPTS = {}
Version = '0.4' 
$cc_cl = Array.new
$to_cl = Array.new 
$ccp_cl = Array.new
$gp = Array.new
$adm = Array.new 
$mailtest = true # do email test is default 
$csv = false
$csvt = false
$supress = false 
$passwd = "" 
$name = "" 
$deb = false
# $deb = true
$ln = false
$an = false 
$mail_send = true 
$resend = false
$notest = false
$hmessage = "" 
def addcl( division)
  puts "Division #{division}" 
  case division
  when "MICE" 
    $objArry = $mice
  when "EVENT" 
    $objArry = $event
  when "EVENTAUD" 
    $objArry = $eventaud
  when "EVENTOSAKA"
    $objArry = $eventosaka
  when "MCRAY" 
    $objArry = $mcray
  when "MCRAYFLAME" 
    $objArry = $mcrayflame
  when "MCRAYS" 
    $objArry = $mcrays
  when "MCRAYE1" 
    $objArry = $mcraye1
  when "COMIDE" 
    $objArry = $comide
  when "COMIDEDD" 
    $objArry = $comidedd
  when "CREDENM" 
    $objArry = $credenm
  when "CREDETC" 
    $objArry = $credetc
  when "CREDEOSAKA" 
    $objArry = $credeosaka
  when "ADMIN" 
    $objArry = $admin
  else 
    puts "No division string #{division}" 
    exit 0 
  end
  p $objArry
  $cc_cl += $objArry
end    
    
def build_config(uname, email, uid, u_pass, pop )
  if uname != nil then
    $uname_c = uname 
  else 
    $uname_c = "設定ファイル" 
  end
  $email_c = email
  $uid_c = uid 
  $u_pass_c = u_pass 
  dom = email.split('@') 
  byebug if $deb  
  if pop == 'POP' then 
    ppx = 'POP' 
  else
    ppx ='IMAP'
  end
  # attach monileconfig file 
  if dom[1] == 'c.ray.co.jp' then 
    fl = "profile/CRAY_#{ppx}.mobileconfig.erb" 
  elsif dom[1] == 'ss.ray.co.jp' then
    fl = "profile/SSRAY_#{ppx}.mobileconfig.erb" 
  elsif dom[1] == 'ray.co.jp' then  
    fl = "profile/RAY_#{ppx}.mobileconfig.erb"
  elsif dom[1] == 'ybb.ne.jp' then 
    fl = "profile/YBB_#{ppx}.mobileconfig.erb"  
  else 
    puts "Domain #{dom[1]}'s profile is not supporrted." 
  end
  $rayID = dom[0]  
  if fl != nil then 
    erb = ERB.new(File.read( fl))
    fname = "tmp/#{email}_#{pop}.mobileconfig"  
    File.open(fname, 'w+') do |f| 
      rstr = erb.result.force_encoding('UTF-8')
      f.write( rstr)  
    end
    return fname 
  else 
    return nil 
  end
end


opt.on('-a', 'anpi was set ') { $an = true }
opt.on('-c VAL', 'cc: address to send report mail no password') {|v| $cc_cl.push(v) }
opt.on('--cp VAL', 'cc: addres to send report copy with password') {|v| $ccp_cl.push(v) } 
opt.on('-C VAL', 'cc: address division to send report mail--valid divs are MICE EVENT EVENTAUD EVENTOSAKA MCRAY MCRAYFLAME MCRAYS MCRAYE1 COMIDE  COMIDEDD CREDENM CREDET CREDEOSAKA ADMIN') {|v| addcl(v) }
opt.on('-d', 'debug mode ') { $deb = true }
opt.on('-e', 'e-mail only') { $mail_only = true }
opt.on('-g VAL', 'group address belonged. ') {|v| $gp.push(v) }
opt.on('-h VAL', 'heading message') { |v| $hmessage = v }
opt.on('-i', 'intra was set ') { $intra = true }
opt.on('-j', 'jobnet was set ') { $jn = true }
opt.on('-l', 'Line Works ID was set ') { $ln = true }
opt.on('-m VAL', 'additional e-mail address') { |v| $adm.push(v) }
opt.on('-n VAL', 'supply name manually' ) { |v| $name = v }
opt.on('-p VAL', 'supply password manually') { |v| $passwd = v }
opt.on('-r', 're-send setting information(s).') { $resend = true }
opt.on('-q VAL', 'division to send creation report.') {|v| $division =v } 
opt.on('-s', 'supress email information') { $supress = true }
opt.on('-t VAL', 'to: address to send report mail') {|v| $to_cl.push(v) }
opt.on('-u', 'output title line of csv') { $csvt = true }
opt.on('-w', 'debug without mail output.') { $mail_send = false }
opt.on('-x', 'do not execute test') { $mailtest = false }
opt.on('-y', 'output report as csv file') { $csv = true }
opt.on('-z', 'no send test for email') {$notest = true } 

rr = opt.parse!(ARGV)
begin  
  p ARGV
  p rr
  puts "ARGV"
  p ARGV 
  puts "OPTS"
  p OPTS 
end if $deb 
$account = ARGV[0] 
 
if $account == nil || $account.length ==0 then 
  # STDERR.i
#  STDERR.puts "Accouint is invalid.(#{$account})" 
  exit(-1)
end
if $resend then 
  $mailtest = false
end 
$shain = ARGV[1]

$slist = Array.new  
$clist = Array.new
$tlist = Array.new 

puts "$mailtest: #{$mailtest}" if $deb 
# $resend = true
# $mailtest = false 
# $supress = false

# $bizhost = "mail01.bizmail2.com" 
$bizhost = "mail.ray.co.jp"
$airhost = "mail.ray.co.jp"
$pop = {"pop3" => "110", "pop3s(SSLを使用)" => "995" }
$imap = { "imap" => "143", "imaps(SSLを使用)" => "993" }
$smtpSend  = { "smtp(submission)" => "587", "smtps(SSLを使用)" => "465"  }
$smtpAuth =  [  "PLAIN", "LOGIN" ]
$imapHost = $bizhost 
# setup server spec parameters.... 

bb = $account.split('@')
p bb if $deb 
if bb == nil then  # check if email is valid
  p bb if $deb
  STDERR.puts "#{$account} is invalid." if $deb
  exit(-1)
end
byebug if $deb 
if bb.size == 1 then
  STDERR.puts("Email address is invalid.")
  exit(-1)  
  puts "bb.size==1" if $deb
  $uid = bb[0]  # $account
  $luid = $account 
  $domain = "wes.co.jp" 
  $host = "wes.co.jp" 
  $smtphost = "wes.co.jp" 
  $ldap = "file" 
  $passfile = $wespassfile 
  $email = $uid + $domain 
  $webmail = ""
  $webmailm = "" 
# check mail domain and server  
elsif $tdomain.index(bb[1]) then # All In One mail 
  STDERR.puts "#{bb[1]}: $tdomain" 
#byebug 
  $uid  = $account 
  $email = $account 
  $domain = bb[1]
  $host = $airhost 
  $smtphostd = "mxin1.airnet.ne.jp" # $airhost for public 
  $smtphost = "mail.ray.co.jp"  # $airhost for domain owner
  if $domain == 'c.ray.co.jp' then 

    $ldap = "file"
    $passfile = $craypassfile
  else 
    $ldap = "ldap.ray.co.jp" 
  end 
#  $pop = { "pop3s(SSLを使用)" => "995" }
#  $imap = { "imaps(SSLを使用)" => "993" }
#  $smtpSend  = { "smtps(SSLを使用)" => "465"  }
#  $sendAuth =  { "auth" => "plain", "auth" => "login" }
  $webmail   = "Webメールアクセス用URL(自動) :https://mail.ray.co.jp/"
  $webmailpc  = "Webメールアクセス用URL(PC)  :https://mail.ray.co.jp/am_bin/amlogin"
  $webmailsp = "Webメールアクセス用URL(スマホ):https://mail.ray.co.jp/am_bin/slogin" 
  $webmailm = "Webメールアクセス用URL(携帯)  :https://mail.ray.co.jp/am_bin/mlogin" 
elsif $udomain.index(bb[1]) then
  puts "#{bb[1]}: $udomain" 
# byebug 
#  $host = "www16276uf.sakura.ne.jp"
#  $smtphost = "www16276uf.sakura.ne.jp"
  $host = "sk1.ray.co.jp"
  $smtphost = "sk1.ray.co.jp"
  $smtphostd = "sk1.ray.co.jp"
  $uid = $account
#  $uid0 = $uid 
  $domain = bb[1]
  $email = $account
#  $webmail = "https://www16276.sakura.ne.jp"
  $webmail = "http://sk1.ray.co.jp"
#  $webmailm = "https://www16276.sakura.ne.jp"
  $webmailm = "http://sk1.ray.co.jp"
  $webmailsp = "" 
  $ldap = "ldap2.ray.co.jp" 
elsif $wdomain.index(bb[1]) then 
  puts "#{bb[1]}: $wdomain" 
# byebug 
  $host = "mas14.kagoya.net"
  $smtphost = "smtp.kagoya.net" 
  $smtphostd = "smtp.kagoya.net" 
  $pop = {"pop3" => "110"}
  $imap = { "imap" => "143"  }
  $smtpSend  = { "smtp" => "587"   }

  puts '-' * 40 
  $pop.each do |key,val|
    print "#{key} => #{val}, " 
  end 
#  byebug 
  puts 
  $imap.each do |key,val|
    print "#{key} => #{val}, " 
  end 
  puts
#  byebug
  $uid = "tcm." + bb[0] 
  $domain = bb[1] 
  $email = $account
  $webmail   = "https://activemail.kagoya.com/"  
  $webmailsp = "https://activemail.kagoya.com/am_bin/slogin?userid=#{$uid}" 
  $webmailmb = "https://activemail.kagoya.com/am_bin/mlogin?userid=#{$uid}" 
  $manual = "http://it3.ray.co.jp/html/mail" 
  $manualm = "http://support.kagoya.jp/manual/startup/mail_account_settings.html#mailclient" 
  $ldap = "file"
  $passfile = $tcmpassfile
elsif $vdomain.index(bb[1]) then # wes.co.jp  
  puts "#{bb[1]}: $vdomain" 
#byebug 
  $host = "mail2.ray.co.jp"
  $pop = {"pop3" => "110", "pop3s(SSLを使用)" => "995" }
  $imap = { "imap" => "143", "imaps(SSLを使用)" => "993" }
  puts '-' * 40 
#  byebug
  $smtphost = "mail2.ray.co.jp" 
  $smtphostd = "mail2.ray.co.jp" 
  $smtpSend  = {"smtp" => "25" , "smtp" => "587", "smtps(SSLを使用)" => "465"  }
  $smtpAuth =  [ "PLAIN", "LOGIN" ] 
  $uid =  bb[0] 
  $domain = bb[1] 
  $email = $account
  $webmail   = "http://wes.co.jp/WEBMAIL/dnwml3/dnwmljs.cgi"  
  $webmailsp = "http://wes.co.jp/WEBMAIL/dnwmljs.cgi" 
  $webmailmb = "http://wes.co.jp/WEBMAIL/dnmwml3/dnmwml.cgi" 
  $manual = "http://it3.ray.co.jp/html/mail" 
  $manualm = "http://web.arena.ne.jp/support/suitex/manual/mail/instruction.html" 
  $ldap = "file"
  $passfile = $wespassfile

elsif $xdomain.index(bb[1]) then # former c.ray.co.jp  (Conoha )
    # SMTP(s)サーバー	smtp.ray.conoha.io	
    # POP(s)サーバー	pop.ray.conoha.io	
    # IMAP(s)サーバー	imap.ray.conoha.io
  if SV ==  "conoha" then 
    puts "#{bb[1]}: $xdomain" 
   #byebug 
    $host = "pop.ray.conoha.io"
    $pop = {"pop3" => "110" , "pop3s" => "995" }
    $imapHost = "imap.ray.conoha.io" 

    $imap = { "imap" => "143", "imaps" => "993" }
    puts '-' * 40 
  #  byebug
    $smtphost = "smtp.ray.conoha.io" 
    $smtphostd = "smtp.ray.conoha.io" 
    $smtpSend  = {"smtp" => "25" , "smtp" => "587"}
    $smtpAuth =  [ "PLAIN", "LOGIN" ] 
    $imaphost = "imap.ray.conoha.io" 
    $uid =  $account
    $domain = bb[1] 
    $email = $account
    $webmail   = "使用不可" # https://secure.sakura.ad.jp/rscontrol/?webmail=1"
    $webmailsp = "使用不可"
    $webmailmb = "使用不可"
    $manual = "http://it3.ray.co.jp/html/mail" 
    $manualm = "https://www.conoha.jp/guide/mailserver.php"
    $ldap = "file"
    $passfile = $craypassfile 
  else 
    puts "#{bb[1]}: $xdomain" 
   #byebug 
    $host = "c.ray.co.jp"
    $pop = {"pop3" => "110" }
    $imap = { "imap" => "143" }
    puts '-' * 40 
  #  byebug
    $smtphost = "c.ray.co.jp" 
    $smtphostd = "c.ray.co.jp" 
    $smtpSend  = {"smtp" => "25" , "smtp" => "587"}
    $smtpAuth =  [ "PLAIN", "LOGIN" ] 
    $uid =  $account
    $domain = bb[1] 
    $email = $account
    $webmail   = ""
    $webmailsp = ""
    $webmailmb = ""
    $manual = "http://it3.ray.co.jp/html/mail" 
    $manualm = "https://help.sakura.ad.jp/app/answers/detail/a_id/2236"
    $ldap = "file"
    $passfile = $craypassfile 
  end
else
  STDERR.puts "Domain #{bb[1]} is not supported."
  STDERR.puts "uid = #{bb[0]}"
  STDERR.puts "not match. exit" 
  exit(-1)
end 
#byebug 
  
## check pop behavior  
  $report = Array.new
  pass = 0
  fail = 0 
  # Set login ID 
  case $domain 
  when 'wes.co.jp' 
    $email = $uid + "@"+ $domain

  else 
#    $email = $account 
#    $uid = $email 
  end 
  begin  
    puts "Domain #{$domain}"
    puts "uid = #{$uid}" 
    puts "email = #{$email}"
    puts "password = #{$passwd}"
    puts "ldap = #{$ldap}" 
  end if $deb
# get account data ....
# get password 
  if ($passwd == "" ) then
    STDERR.puts("email:#{$email},passfile=#{$passfile},domain=#{$domain}") if $deb
    $passwd = getpassG($email,$passfile,$domain) 
    if $passwd == nil || $passwd.length < 1 then 
      STDERR.puts("Cannot get password. quiting....")  
      exit(-1)
    else 
      puts "password = #{$passwd}" if $deb 
    end 
  end
  if ($name == "") then
    if ($ldap == 'file') then  
      if ($name = getname_from_file($email,$passfile,$domain)) == true then 
        STDERR.puts "Cannot get name.#{$email} "
        exit(-1)
      end 
    elsif ($name = getname($email)) == true then 
      STDERR.puts "Cannot get name."
      exit(-1)
    else 
      gname = getgname($email) 
    end
  end 
  if $shain == nil || $shain.length ==0  then
    if $ldap != 'file' then 
      $shain = ldapvalue( "mail", $email, "employeeNumber",$ldap) 
    else 
      $shain = "-99999" 
    end
    if $shain == nil || $shain.length == 0 then 
##      $shain = "-9999" 
    end 
  end 
  if $shain == nil || $shain.length < 4 then  
    STDERR.puts "Need shain number... exit with error"
    exit(-1) 
  end 
  if $logpath then 
    $log = Logger.new($logpath)
    $log.level = Logger::INFO
    $log.info(("#{File.basename(__FILE__)} checking #{$email}:name:#{$name}").force_encoding('UTF-8'))
  end
  #byebug  
  popsrv = $host
  smtpsrv = $smtphost

  usessls = $smtpSend.to_s.include?("SSL")  
  usesslr = $pop.to_s.include?('SSL') 
  if (($mailtest == true) || ($supress == false)) then # do mail test 
    if !$resend  then 
      puts "popcheck uid #{$uid}, #{popsrv}, #{$passwd} SSL:#{usesslr} " if $deb 
      res = popcheck($uid , popsrv, $passwd, $deb , usesslr  )
    else 
      res = 0 
    end  
    if res then
      fail += 1 
      $report.push  "#{$uid}:受信テスト失敗.#{Time.now}"
    else
      pass +=1 
      $report.push  "受信テスト成功.#{Time.now}"
    end
  ## check smtp delivery
    if (! $notest || $resend )  then 
      res = smtpcheck( $uid , smtpsrv , 'xxxxx' , $email , 'r', $deb, $domain , usessls )
      if res then
        fail += 1 
        $report.push  "#{$uid}:送信テスト失敗.#{Time.now}"
      else
        pass +=1 
        $report.push  "送信テスト成功.#{Time.now}"
      end
      ## check reg to spam filter  
    end
  ## check smtp Auth   
    puts "$uid: #{$uid}, $uid0: #{$uid0} $domain: #{$domain},#{usessls}" if $deb 
  #  byebug
    if $mailtest then 
      res = smtpcheck( $uid , smtpsrv, $passwd , 'ken@ml.ray.co.jp' , 'a', $deb, $domain, usessls )
      if res then 
        fail += 1 
        $report.push  "#{$uid}:AUTH送信テスト失敗.#{Time.now}"
      else
        pass +=1 
        $report.push  "AUTH送信テスト成功.#{Time.now}"
      end
    end 
  end 
  if !$supress then  
    $slist.push(("e-mail").force_encoding('UTF-8')) 
  end
  # adjust encoding.. etc 
  # byebug 
  if $name.nil? then 
    $name = "EMPTY_NAME" 
  end  
  $name.rstrip!
  # $email.rstrip! 
  # $uid.rstrip! 
  $conf_file1 = build_config($name, $email.rstrip, $uid.rstrip, $passwd, 'POP') 
  $conf_file2 = build_config($name, $email.rstrip, $uid.rstrip, $passwd, 'IMAP') 
  $email = ($email.encode('utf-8')) 
  ## additional e-mail ??

  if $intra then 
    $slist.push("イントラネット")
  end
  if $jn then 
    $slist.push("ジョブネット")
  end
  if $ln then 
    $slist.push("LINE Works")
  end
  if $an then 
    $slist.push("安否確認システム")
  end
if fail > 0 then 
  STDERR.puts "fail:#{fail},pass:#{pass}"
  unless $mailtest   
    fail=0
    pass=4
  end 
else 
  STDERR.puts "fail:#{fail},pass:#{pass}"
end
  $sl = $slist.join("、")
  puts "pass:#{pass}, fail:#{fail}" if $deb 
#  byebug 
  $to = Array.new
  $cc = Array.new 
  if (fail > 0)  then # Error in test phase.... 
    $to.push 'ken@ray.co.jp'
    $subj = "#{$sl}設定完了報告(※)"
    STDERR.puts "mail will not be sent because of error(s) in test. "  
  else #  if (pass > 0)   ## send error main  
    $to.push($email)
    $cc.push('mail-support@ray.co.jp')
    $subj = "#{$sl}設定完了報告"
  end
# mail result to user
#    p Mail.defaults 
#    Mail.defaults do 
#      delivery_method(:smtp ,
#      port: 587 
#    )
#    end  

# byebug 
# compiling body..... 
def body_add( body) 
  name1 = "名前:" + ($name.chomp).force_encoding('utf-8') if $name != nil 
  passread = ""
  if $passwd != nil then
    passread = kanayomi($passwd)
  else
    passread = ""
  end

  body.push(name1) if name1 != nil 
  if $name != nil then 
    $clist.push(($name.chomp).force_encoding('UTF-8'))
    $tlist.push(("名前").force_encoding('UTF-8'))
    # add shain number 
    byebug if $deb  
    if ($shain.to_i < 10000) then 
      ttls = "社員番号"
    else 
      ttls = "管理番号" 
    end 
    tshain = "#{ttls}:#{$shain}"
    $tlist.push(ttls) #.force_encoding('UTF-8'))
    $clist.push($shain.to_s) # .force_encoding('UTF-8'))
    body.push(tshain)
  end
  if !$supress then 
    body.push("e-mail:#{$email}")
#  body.push("メールID:#{$uid}")
    body.push("ログインID:#{$uid}")

    body.push("ログインパスワード:#{$passwd}")

    body.push("(#{passread})")
    body.push("")
   # for csv
    $tlist.push(("e-mail").force_encoding('UTF-8'))
    $tlist.push("ログインID")
    $tlist.push("ログインパスワード")
#    $tlist.push("パスワード読み")
   
    $clist.push(($email)) 
    $clist.push(($uid).encode('UTF-8'))
    $clist.push(($passwd).force_encoding('UTF-8'))
#    $clist.push(passread)
# byebug  
    if $gp.size > 0 then 
      body.push( "所属グループメール：#{$grp}")
    else 
      body.push "" 
    end
    body.push( "-" * 50 ) 
    body.push("受信サーバー:#{$host}")
    str = "" 
    $pop.each do |key,val| 
      if str != "" then 
        str += ", "
      end 
      str += sprintf("%s:(Port:%s)", key,val)
      STDERR.puts str 
    end 
    body.push str 
    str = "" 
    if $imapHost != nil then 
  #    body.push("受信サーバー(IMAP):#{$imapHost}")
    end
    $imap.each do |key,val| 
      if str != "" then 
        str += ", "
      end 
      str += sprintf("%s:(Port:%s)", key,val)
      STDERR.puts str 
    end 
    if str.length > 0 then  
      body.push str 
      str = "" 
      body.push "IMAPは非推奨です。通常のメールでは使用しないでください。"
    end 
  
  #("  POP3s (Port:995):SSL          または")
     # #body.push("  IMAP4s(Port:993):SSL")
    body.push("送信サーバー:#{$smtphost}") 
    str = "" 
    $smtpSend.each do |key,val| 
      if str != "" then 
        str += ", "
      end 
      str += sprintf("%s:(Port:%s)", key,val)
      STDERR.puts str 
    end 
    body.push str 
#    body.push("  SMTPs (Port:465):")
    
#    body.push("認証:PLAIN, LOGIN")
    str = "SMTP認証:" + $smtpAuth.join(',')
    body.push str 
    body.push("-" * 50)

    body.push( $webmail ) if $webmail != nil 
    body.push( $webmailpc ) if $webmailpc != nil 
    body.push( $webmailsp ) if $webmailsp != nil 
    body.push( $webmailm ) if $webmailm != nil 
    body.push("社内システム設定マニュアル:#{$manual}") if $manual != nil 
    body.push("メールアプリケーション設定マニュアル:#{$manualm}") if $manualm != nil 
#byebug
    bend = 8
    if $adm.size > 0 then 
      $adm.each do |addr|
        body.push("e-mail:#{addr}") 
        body.push("") 
        bend += 2
      end
    end
    if $resend == true then 
      body.push  "" 
      body.push  "" 
      bend += 2 
    else 
      body.push  "------------------------アカウントテスト結果-------------------------\n"
      bend += 1 
    end 
                  
    $mess1 = body.join("\n")
    if $resend != true then 
      $mess1 += $report.join("\n")+ "\n"+ "-"*70 + "\n"
    end
  else
    body.push("\n") 
    $mess1 = body.join("\n")  
    $mess1 += "-"*70 + "\n"
  end 
end

def add_mes( )  
  if $intra then
    puts "no mailtest will be done "
    `scp -P 51343 ken@intra.ray.co.jp:/var/www/cgi-bin/pass.txt ~/home/ken/tmp/` if $mailtest 
  # `scp root@intra.ray.co.jp:/var/www/cgi-bin/pass.txt /tmp/ ` 
     if ($shain == nil || $shain.length < 4) then 
       STDERR.puts("You must supply shain # manually. commnad email shain# ")
       exit( -1)     
     end
     intr  = Array.new 
     intr.push("イントラログインID:#{$shain}")
     passread = ""
     if $passwd != nil then
       passread = kanayomi($passwd)
     else
       passread = ""
     end
  

    intr.push("イントラ初期パスワード:#{$passwd}")
    intr.push("(#{passread})") 
    # csv section
    $tlist.push("イントラログインID")
    $tlist.push("イントラ初期パスワード")
#    $tlist.push("イントラパスワード読み") 
    $clist.push($shain)
    $clist.push($passwd)
#    $clist.push(passread)
#     byebug 
    ps = get_last_line("/home/ken/tmp/pass.txt")
    today = Date.today 
    if today.day > 24 then 
      today += 10 
    end 
    mnt = today.month  
    intr.push("#{mnt}月の会社ID:#{ps}")
    intr.push("https://intra.ray.co.jp/ ")
    $mess1 += intr.join("\n") + "\n"+ "-"*70 + "\n"
  end 
  if $jn then 

    jb = Array.new 
    jb.push("JobnetログインID:#{$shain}")
    jb.push("Jobnet初期パスワード:#{$passwd}")
    jb.push("(#{passread})")
    # csv 
    $tlist.push("JobnetログインID")
    $tlist.push("Jobnet初期パスワード")
    $tlist.push("Jobnetパスワード読み") 
    $clist.push($shain)
    $clist.push($passwd)
#    $clist.push(passread)

    jb.push("http://jobnet.ray.co.jp/RJ/ ") 
    $mess1 += jb.join("\n") + "\n"+ "-"*70 + "\n"
  end
  if $ln then 
    lng = Array.new
    lng[0] = "LINE WORKS ID:#{$rayID}@raydb"
    lng[1] = "LINE WORKS 初期パスワード:#{$passwd}"
    lng[2] = "(#{passread})" 
    lng[3] = "https://auth.worksmobile.com/login/login?"
    # csv 
    $tlist.push("LINE WORKSログインID")
    $tlist.push("LINE WORKS初期パスワード")
#    $tlist.push("LINE WORKS パスワード読み") 
    $clist.push($rayID + "@raydb") 
    $clist.push($passwd)
#    $clist.push(passread)
    $mess1 += lng.join("\n") + "\n"+ "-"*70 + "\n"
  end 
  if $an then 
    anp = Array.new
    anp[0] = "安否確認システム企業コード:4317"
    anp[1] = "安否確認システムユーザーID:#{$shain}"
    anp[2] = "安否確認システム初期パスワード:4317"
    anp[3] = "https://www.e-kakushin.com/login/" 
    # csv 
    $tlist.push( "安否確認システム企業コード")
    $tlist.push( "安否確認システムユーザーID")
    $tlist.push( "安否確認システム初期パスワード")
    $clist.push(("4317").force_encoding("utf-8"))
    $clist.push(($shain).force_encoding("utf-8"))
    $clist.push(("4317").force_encoding("utf-8"))

    $mess1 += anp.join("\n")+ "\n"+ "-"*70 + "\n"
  end
end 
  #  byebug 
  # build_config($name.chomp, $email, $uid, $passwd)

  mail = Mail.new
#  mail.delivery_method(:smtp,
#    address:        "mail01.bizmail2.com",
#    port:           465,
#    debug:          true,
#    domain:         "ray.co.jp",
#    authentication: :login,
#    ssl:            true,
#   user_name:      "mtest@ray.co.jp",
# #   user_name:      "mail-support@ray.co.jp",
# #  password:       "ray12345"
#    password:       "s3cy4UL9"
#  )

#   mail.charset = 'ISO-2022-JP' 
   mail.charset = 'UTF-8' 
   mail.from = 'ken@ray.co.jp'
#  mail.smtp_envelope_to = 'ken@ray.co.jp'
#  mail.reply_to = 'loginfo@ray.co.jp' 
# byebug 
  if $deb then 
    mail.to = 'ken@ray.co.jp' 
    $cc.push($cc_cl)
    mail.cc = $cc.uniq.join(",")
  #  mail.cc = "" 
    puts "mail to:#{mail.to}" 
    puts "mail cc:#{mail.cc}"  
  else
    $to.push($to_cl)  
    mail.to = $to.uniq.join(",") 
    if $resend != true then 
      $cc.push($adminary)
    else 
      $cc.push('ict@ray.co.jp')
    end  
    $cc.push($cc_cl)
    mail.cc = $cc.uniq.join(",")
  end
#  $cmd = "util/passtr.py #{$passwd} > pass.txt" 
#  p $cmd 
#  puts system($cmd) 
  if $gp.size == 0 then 
    $grp = "無し"
  else 
    $grp = $gp.join(',')
  end 
  # special fix
  passread = ""
  if $passwd.class == 'TrueClass' then
    $passwd = ""
    byebug 
  end  
  if $passwd != nil then 
    passread = kanayomi($passwd) 
  else 
    passread = "" 
  end 
  body = Array.new 
  if $hmessage.length > 0 then 
    body.push($hmessage)
  #  body.push( '-' * 40) 
  else 
    if $resend then 
      body.push( "ITシステムの設定情報をお知らせ致します。") 
      body.push( 'ITシステムサポートはこちら：https://it3.ray.co.jp/html/' )
      $subj = "#{$sl}設定情報"
      body.push("対象項目：#{$slist}")
    else 
      body.push("ITシステム設定が完了致しましたのでご連絡致します。")
      body.push( 'ITシステムサポートはこちら：https://it3.ray.co.jp/html/' )
      body.push("設定項目：#{$slist}")
    end
  end
  # byebug
  body_add(body) 
  add_mes( ) 
  begin  
    nm = "名前:#{$name}"
    if ((gname != nil) && (gname.length > 0)) then 
      nm += " (#{gname})" 
    end
    nm = nm.force_encoding('utf-8')  
  rescue => ex 
    #p ex
  end 
  name1 = "名前:" + ($name.chomp).force_encoding('utf-8') if $name != nil 
  prenc $clist 
  prenc $tlist 
  res = "" 
  if $csv then
    if $csvt then  
      puts $tlist.join(',')
    end 
    puts $clist.join(',')
  else  
    STDERR.puts "sending report via email to #{mail.to},cc:#{mail.cc}." 
#    mail.body  =  NKF.nkf('-Wj', $mess1).force_encoding("ASCII-8BIT")
#    mail.subject = NKF.nkf('-WMm0j', $subj).force_encoding("ASCII-8BIT")
    mail.body  =  $mess1 + "\nReported by #{$PROGRAM_NAME}"  # .force_encoding("ASCII-8BIT")
    mail.subject = $subj  # .force_encoding("ASCII-8BIT")
    mail.add_file($conf_file1) if ($conf_file1 != nil)  
    mail.add_file($conf_file2) if ($conf_file2 != nil) 
#  byebug 
    begin 
      if $deb then 
        p mail.delivery_method 
        puts mail.body
      end 
      
      res = mail.deliver if $mail_send
      puts "mail had sent successfully"
      puts "メールを送信しました。"
      puts "mailed to #{mail.to}" 
      puts "       cc #{mail.cc}" 
      $log.info("sent report: #{$email},to:#{mail.to},cc:#{mail.cc}") 
    rescue => ex
      res = "Failed to send.#{ex.to_s}" 
      $log.error("Failed to send.#{ex.to_s}") 
      # p ex
      exit(-1)
    end 
    exit(0)
  end
  exit(0)
#  end


