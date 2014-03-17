#!/usr/local/bin/ruby 
# encoding : utf-8 
require 'optparse'
require './popchecks.rb'
require './ldaputil.rb'
require 'mail'
require 'nkf'

$tdomain = [ "ray.co.jp", "plays.co.jp", "digisite.co.jp","wes.co.jp","tc-max.co.jp" ]
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
puts "e-mail , shain # " 
opt.on('-c VAL', 'cc: address to send report mail') {|v| $cc.push(v) }
opt.on('-t VAL', 'to: address to send report mail') {|v| $to.push(v) }
opt.on('-g VAL', 'group address belonged. ') {|v| $gp.push(v) }
opt.on('-m VAL', 'additional e-mail address') { |v| $adm.push(v) } 
opt.on('-n VAL', 'supply name manually' ) { |v| name = v }
opt.on('-p VAL', 'supply password manually') { |v| passwd = v } 
opt.on('-d', 'debug mode ') { deb = true }
opt.on('-l', 'linguinet  ') { $ln = true }
opt.on('-j', 'jobnet was set ') { $jn = true }
opt.on('-i', 'intra was set ') { $intra = true }
opt.on('-a', 'anpi was set ') { $an = true }
opt.on('-r', 're-send setting information(s).') { $resend = true } 
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
if bb == nil then 
  p bb
  puts "#{$account} is invalid."
  exit -1
elsif bb.size == 1 then
  $uid = $account
  $domain = "ray.co.jp" 
elsif $tdomain.index(bb[1]) then
  $uid = bb[0]
  $domain = bb[1]
else 
  puts "Domain #{bb[1]} is not supported."
  puts "uid = #{bb[0]}" 
  exit -1
end 
  puts "Domain #{$domain}."
  puts "uid = #{$uid}" 

## check pop behavior  
  report = Array.new
  pass = 0
  if(( $domain == 'ray.co.jp')||($domain == 'wes.co.jp')) then  
    email = $uid + "@"+ $domain
  end
  p email
  if (passwd == "" ) then 
    if (passwd = getpass(email)) == true then 
      puts "Cannot get password."
      exit -1
    end
  end
  if (name == "") then 
    if (name = getname(email)) == true then 
      puts "Cannot get name."
      exit -1
    else 
      gname = getgname(email) 
    end
  end 

  puts("pass:#{passwd},name:#{name}")
  if $domain == "wes.co.jp" then 
    popsrv = "wes.co.jp" 
    smtpsrv = "wes.co.jp" 
  elsif $domain == "wes.co.jp" then 
    popsrv = "pop.ray.co.jp" 
    smtpsrv = "smtp.ray.co.jp" 
  elsif $domain == "tc-max.co.jp" then 
    popsrv = "tc-max.co.jp" 
    smtpsrv = "smtp.tc-max.co.jp" 
  end 
  res = popcheck($uid , popsrv, passwd, deb )
  if res then 
    report.push  "#{$uid}:受信テスト失敗.#{Time.now}"
  else
    pass +=1 
    report.push  "#{$uid}:受信テスト成功.#{Time.now}"
  end
## check smtp delivery 
  res = smtpcheck( $uid , smtpsrv , 'xxxxx' , email , 'r', deb, $domain )
  if res then 
    report.push  "#{$uid}:送信テスト失敗.#{Time.now}"
  else
    pass +=1 
    report.push  "#{$uid}:送信テスト成功.#{Time.now}"
  end
## check reg to spam filter  
  if ($domain == "wes.co.jp") || ($domain == "tc-max.co.jp") then 
    ## pass spam filter test 
    puts "Spam filter test is skipped." 
  else 
    res = smtpcheck( $uid , 'cluster5.us.messagelabs.com', 'xxxxx' , email , 'r', deb, $domain)
    if res then 
      report.push  "#{$uid}:SPAMフィルター送信テスト失敗.#{Time.now}"
    else
      pass +=1 
      report.push  "#{$uid}:SPAMフィルター送信テスト成功.#{Time.now}"
    end
  end 
## check smtp auth  
  res = smtpcheck( $uid , smtpsrv, passwd , 'ken7wiz@ybb.ne.jp' , 'a', deb, $domain )
  if res then 
    report.push  "#{$uid}:AUTH送信テスト失敗.#{Time.now}"
  else
    pass +=1 
    report.push  "#{$uid}:AUTH送信テスト成功.#{Time.now}"
  end
  p report
  $slist = Array.new  
  $slist.push("e-mail")
  ## additional e-mail ??

  if $intra then 
    $slist.push("イントラネット")
  end
  if $jn then 
    $slist.push("ジョブネット")
  end
  if $ln then 
    $slist.push("稟議ネット")
  end
  if $an then 
    $slist.push("安否確認システム")
  end
  $sl = $slist.join("、")
  puts pass
  if $domain == "wes.co.jp" then 
    psnum = 3
  else 
    psnum = 4
  end 
  if pass < psnum  then 
    $toaddr = 'ken@ray.co.jp'
    $ccaddr = '' 
    $subj = "#{$sl}設定完了報告(未完了)"
    $adminaddr = "" 
  else  ## send error main  
    $to.push(email)
    $cc.push('ken@ray.co.jp')
    $to.uniq! 
    $cc.uniq! 
    $toaddr = $to.join(",")
    $ccaddr = $cc.join(',')
    $subj = "#{$sl}設定完了報告"
# mail result to user 
    mail = Mail.new
    mail.charset = 'ISO-2022-JP' 
    mail.from = 'ken@ray.co.jp'
    if deb then 
      mail.to = 'ken@ray.co.jp' 
    else 
      mail.to = $toaddr 
      if $resend != true then 
        mail.cc = $ccaddr + $adminaddr 
      end 
    end
#    $cmd = "util/passtr.py #{passwd} > pass.txt" 
#    p $cmd 
#    puts system($cmd) 
    if $gp.size == 0 then 
      grp = "無し"
    else 
      grp = $gp.join(',')
    end 

    passread = "" 
    passread = kanayomi(passwd) 
    body = Array.new 
    if $resend then 
      body[0] = "ITシステムの設定情報をお知らせ致します。"
      $subj = "#{$sl}設定情報"
    else 
      body[0] = "ITシステム設定が完了致しましたのでご連絡致します。"
    end 
    body[1] = "設定項目：#{$slist}"
    body[2] = "名前:#{name}"
    if ((gname != nil) && (gname.length > 0)) then 
      body[2] += " (#{gname})" 
    end 
    body[3] = "e-mail:#{email}"
    body[4] = "メールID:#{$uid}"
    body[5] = "メールPass:#{passwd}"
    body[6] = "(#{passread})"
    if $gp.size > 0 then 
      body[7] = "所属グループメール：#{grp}"
    else 
      body[7] = "" 
    end 
    bend = 8
    if $adm.size > 0 then 
      $adm.each do |addr|
      body[bend] = "e-mail:#{addr}" 
      body[bend+1] = "" 
      bend += 2
    end
  end 
  if $resend == true then 
    body[bend] = "" 
    body[bend+1] = "" 
    bend += 2 
  else 
    body[bend] = "------------------------アカウントテスト結果-------------------------\n"
    bend += 1 
  end 
                  
  $mess1 = body.join("\n")
  if $resend != true then 
    $mess1 += report.join("\n")+ "\n"+ "-"*70 + "\n"
  end 

  if $intra then 
    `scp root@intra.ray.co.jp:~/pass.txt .` 
    intr  = Array.new 
    intr[0] = "イントラログインID:#{$shain}"
    intr[1] = "イントラパスワード:#{passwd}"
    intr[2] = "(#{passread})" 
    ps = File.read("pass.txt").chomp
    intr[3] = "今月の会社ID:#{ps}"
    intr[4] = "http://intra.ray.co.jp/ " 
    $mess1 += intr.join("\n") + "\n"+ "-"*70 + "\n"
  end 
  if $jn then 

    jb = Array.new 
    jb[0] = "JobnetログインID:#{$shain}"
    jb[1] = "Jobnetパスワード:#{passwd}"
    jb[2] = "(#{passread})"
  
    jb[4] = "http://jobnet.ray.co.jp/rj/ " 
    $mess1 += jb.join("\n") + "\n"+ "-"*70 + "\n"
  end
  if $ln then 
    lng = Array.new
    lng[0] = "稟議ネットログインID:#{$shain}"
    lng[1] = "稟議ネットパスワード:#{passwd}"
    lng[2] = "(#{passread})" 
    lng[3] = "http://linguinet.ray.co.jp/xpoint/login.jsp?domCd=RAY" 
    $mess1 += lng.join("\n") + "\n"+ "-"*70 + "\n"
  end 
  if $an then 
    anp = Array.new
    anp[0] = "安否確認システム企業コード:4317"
    anp[1] = "安否確認システムユーザーID:#{$shain}"
    anp[2] = "安否確認システムパスワード:4317"
    anp[3] = "https://www.e-kakushin.com/login/" 
    $mess1 += anp.join("\n")+ "\n"+ "-"*70 + "\n"
  end 

  puts "sending report via email......" 
  mail.body  =  NKF.nkf('-Wj', $mess1).force_encoding("ASCII-8BIT")
  mail.subject = NKF.nkf('-WMm0j', $subj).force_encoding("ASCII-8BIT")
  if deb then 
    puts mail.body
    mail.deliver 
  else 
    mail.deliver 
  end
end 
