#!/usr/local/bin/ruby 

# encoding : utf-8 
require 'optparse'
require './popchecks.rb'
require './ldaputil.rb'
require 'mail'
require 'nkf'
require 'logger'
require 'tracer' 

# handled by smtp.ray.co.jp 
# $tdomain = [ "ray.co.jp", "plays.co.jp", "digisite.co.jp" ]
# handled by sakura server www16276uf.sakura.ne.jp 
# $udomain = [ "ss.ray.co.jp" , "nissayseminar.jp", "nissayspeech.jp", "mcray.jp", "lic.prent.jp" ]


## main start

Encoding.default_internal = "UTF-8" 

opt = OptionParser.new
OPTS = {}
Version = '0.1' 
$cc = Array.new
$to = Array.new 
$gp = Array.new
$adm = Array.new 
$mailtest = true # do email test is default 
$csv = false
$csvt = false
$supress = false 
passwd = "" 
name = "" 
$deb = false
$ln = false
$an = false 
$resend = false
$hmessage = "" 
def prenc(ary)
  if $deb then 
    puts "#{ary.length} itens in array"  
    inum = 0
    for i in ary do 
      inum += 1 
      puts "#{inum}:#{i} : (#{i.encoding})"
    end
  end 
end 

opt.on('-c VAL', 'cc: address to send report mail') {|v| $cc.push(v) }
opt.on('-t VAL', 'to: address to send report mail') {|v| $to.push(v) }
opt.on('-g VAL', 'group address belonged. ') {|v| $gp.push(v) }
opt.on('-m VAL', 'additional e-mail address') { |v| $adm.push(v) } 
opt.on('-h VAL', 'heading message') { |v| $hmessage = v } 
opt.on('-n VAL', 'supply name manually' ) { |v| name = v }
opt.on('-p VAL', 'supply password manually') { |v| passwd = v } 
opt.on('-d', '$debug mode ') { $deb = true }
opt.on('-s', 'supress email information') { $supress = true } 
opt.on('-u', 'output title line of csv') { $csvt = true } 
opt.on('-x', 'do not mail admin') { $noadm = true } 

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
  STDERR.puts "Acconut is invalid.(#{$account})" 
  exit(-1)
end
$shain = ARGV[1]
if (($deb == true) ||( $resend == true )) then 
  $adimnaddr =""  # don't send to admin, when $debug  
end   

puts "$mailtest: #{$mailtest}" if $deb 

bb = $account.split('@')
p bb if $deb 
if bb == nil then  # check if email is valid
  p bb if $deb
  puts "#{$account} is invalid." if $deb
  exit(-1)
end

def get_last_line(file_path)
  last_line = "" 
  open(file_path) do |file|
    lines = file.read
    lines.each_line do |line|
      last_line = line
    end
  end
  return last_line.chomp
end 

## check pop behavior  
  report = Array.new
  pass = 0
  fail = 0 
  # Set login ID 
  case $domain 
  when 'ray.co.jp','wes.co.jp' 
    email = $uid + "@"+ $domain
  else 
    email = $account 
    $uid = email 
  end 
  if $logpath then 
    log = Logger.new($logpath)
    log.level = Logger::INFO
    log.info(("sending system info to #{email}:name:#{name}").force_encoding('UTF-8'))
  end 
  popsrv = $host
  smtpsrv = $host
  $slist = Array.new  
  $clist = Array.new
  $tlist = Array.new 
  if !$supress then  
    $slist.push(("e-mail").force_encoding('UTF-8')) 
  end
  # adjust encoding.. etc 
  email = (email.encode('utf-8')) 
  ## additional e-mail ??

#      port: 587 
#    )
#    end  

    mail = Mail.new
    mail.charset = 'ISO-2022-JP' 
#    mail.from = 'ken@ray.co.jp'
    mail.from = 'support@ray.co.jp'
    if $deb then 
      mail.to = 'ken@ray.co.jp' 
    else 
      mail.to = $toaddr 
      if $resend != true then 
        if ($noadm == nil || $noadm== false) then 
          mail.cc = $ccaddr + $adminaddr 
        else 
          mail.cc = $ccaddr 
        end
      else 
        mail.cc = $ccaddr 
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

    # special fix 
    case email 
    body = Array.new 
    if $hmessage.length > 0 then 
      body.push($hmessage)
      body.push( '-' * 40) 
    end 
    body.push( "#{$domain} ドメインのメールをご使用の方にメールシステムトラブルのご報告です。")
    $subj = "#{$domain}ドメイン　メールシステム障害発生のお知らせ"
    dody.push( "11/29日   
 end
    begin  
      nm = "名前:#{name}"
      if ((gname != nil) && (gname.length > 0)) then 
        nm += " (#{gname})" 
      end
      nm = nm.force_encoding('utf-8')  
    rescue => ex 
      p ex
    end 
    name1 = "名前:" + (name.chomp).force_encoding('utf-8') 
    body.push(name1)
    body.push("e-mail:#{email}")
    body.push("メールID:#{$uid}")
    body.push("メールPass:#{passwd}")
    body.push("(#{passread})")
    body.push("")
    # for csv
    $tlist.push(("名前").force_encoding('UTF-8'))
    $tlist.push(("e-mail").force_encoding('UTF-8'))
    $tlist.push("メールID")
    $tlist.push("メールパスワード")
    $tlist.push("パスワード読み")
    
    $clist.push((name.chomp).force_encoding('UTF-8'))
    $clist.push((email)) 
    $clist.push(($uid).encode('UTF-8'))
    $clist.push((passwd).force_encoding('UTF-8'))
    $clist.push(passread)

    if $gp.size > 0 then 
      body.push( "所属グループメール：#{grp}")
    else 
      body.push "" 
    end 
    body.push("受信サーバー:#{$host}")
    body.push("  POP3  (Port:110):暗号化無し   または")
    body.push("  POP3s (Port:995):SSL          または")
    body.push("  IMAP4 (Port:143):暗号化無し   または")
    body.push("  IMAP4s(Port:993):SSL          または")
    body.push("送信サーバー:#{$smtp}") 
    body.push("  SMTP  (Port:25 ):暗号化無し   または")
    body.push("  SMTP  (Port:587):暗号化無し   または")
    body.push("  SMTPs (Port:465):")
    body.push("認証:PLAIN, LOGIN")
    body.push("")

    bend = 8
    if $adm.size > 0 then 
      $adm.each do |addr|
        body.push(  "e-mail:#{addr}" )
        body.push( "" ) 
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
      $mess1 += report.join("\n")+ "\n"+ "-"*70 + "\n"
    end 

    if $intra then 
      `scp root@intra.ray.co.jp:/var/www/cgi-bin/pass.txt .` 
      intr  = Array.new 
      intr[0] = "イントラログインID:#{$shain}"
      intr[1] = "イントラ初期パスワード:#{passwd}"
      intr[2] = "(#{passread})" 
      # csv section
      $tlist.push("イントラログインID")
      $tlist.push("イントラ初期パスワード")
      $tlist.push("イントラパスワード読み") 
      $clist.push($shain)
      $clist.push(passwd)
      $clist.push(passread)
   
      ps = get_last_line("pass.txt")
    
      intr[3] = "今月の会社ID:#{ps}"
      intr[4] = "http://intra.ray.co.jp/ " 
      $mess1 += intr.join("\n") + "\n"+ "-"*70 + "\n"
    end 
    if $jn then 

      jb = Array.new 
      jb[0] = "JobnetログインID:#{$shain}"
      jb[1] = "Jobnet初期パスワード:#{passwd}"
      jb[2] = "(#{passread})"
      # csv 
      $tlist.push("JobnetログインID")
      $tlist.push("Jobnet初期パスワード")
      $tlist.push("Jobnetパスワード読み") 
      $clist.push($shain)
      $clist.push(passwd)
      $clist.push(passread)
  
      jb[4] = "http://jobnet.ray.co.jp/rj/ " 
      $mess1 += jb.join("\n") + "\n"+ "-"*70 + "\n"
    end
    if $ln then 
      lng = Array.new
      lng[0] = "稟議ネットログインID:#{$shain}"
      lng[1] = "稟議ネット初期パスワード:#{passwd}"
      lng[2] = "(#{passread})" 
      lng[3] = "http://linguinet.ray.co.jp/xpoint/login.jsp?domCd=RAY" 
      # csv 
      $tlist.push("稟議ネットログインID")
      #tliat.push("稟議ネット初期パスワード")
      $tlist.push("稟議ネットパスワード読み") 
      $clist.push($shain) 
      $clist.push(passwd)
      $clist.push(passread)
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
    prenc $clist 
    prenc $tlist 
    if $csv then
      if $csvt then  
        puts $tlist.join(',')
      end 
      puts $clist.join(',')
    else  
      STDERR.puts "sending report via email......" 
      mail.body  =  NKF.nkf('-Wj', $mess1).force_encoding("ASCII-8BIT")
      mail.subject = NKF.nkf('-WMm0j', $subj).force_encoding("ASCII-8BIT")
      begin 
        if $deb then 
          puts mail.body
          mail.deliver 
        else 
          mail.deliver 
        end
      rescue => ex
        p ex
      end 
    end
  end
