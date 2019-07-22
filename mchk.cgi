#!/usr/local/bin/ruby -W0
# encoding : utf-8 

require 'net/ldap'
require 'cgi'
require 'logger'
require './passwdgen.rb' 
require './ldaputil.rb' 
require 'tracer' 
require 'romaji'
require 'moji' 
require 'byebug' 

def sjis_safe(str)
  if str == nil then
    return nil
  end
  [
    ["301C", "FF5E"], # wave-dash
    ["2212", "FF0D"], # full-width minus
    ["00A2", "FFE0"], # cent as currency
    ["00A3", "FFE1"], # lb(pound) as currency
    ["00AC", "FFE2"], # not in boolean algebra
    ["2014", "2015"], # hyphen
    ["2016", "2225"], # double vertical lines
  ].inject(str) do |s, (before, after)|
    s.gsub(
      before.to_i(16).chr('UTF-8'),
      after.to_i(16).chr('UTF-8'))
  end
end

def sjis_conv(str)
  ss = sjis_safe(str)
  if ss == nil then
    return nil
  else
    return ss # str.encode('Shift_JIS')
  end
end

# check and create 
# todo 
# check local part for @ray.co.jp and @ss.ray.co.jp 
#$DEBUG = "9" 
def exit_job
#  $result += $force  
  if $mail && ($mail.index('@') == nil) then 
    begin 
      p $mail
      p $domain
      p $result 
    end if $DEBUG != "0" 
    $result += "Email Address Error!#{$mail}"  
  end 
#    if $domain != nil then 
#      $mail += '@' 
#      $mail += $domain
#      puts "mail :#{$mail}" if $DEBUG  
#    end   
  redirect_url = 'mchk.rhtml' + '?' + "result=#{$resk}__#{$result}&email=#{$mail}&domain=#{$domain}&shain=#{$shain}&passwd=#{$passwd}&mei=#{$mei}&sei=#{$sei}&name=#{$name}&f_name=#{$f_name}&force=#{$force}" 

  ## $log.warn( cgi.header({ 'status' => 'REDIRECT', 'Location' => redirect_url} ))
  print $cgi.header({ 'status' => 'REDIRECT', 'Location' => redirect_url} )
  
end 

def exit_finish
  $cgi.out() do
    $cgi.html() do
      $cgi.head{ $cgi.title{"メールアドレス作成完了"} } +
      $cgi.body() do
        $cgi.form() do
          $cgi.textarea("get_text") +
          $cgi.br +
          $cgi.submit
        end +
        $cgi.p do
          $cgi.a("bizmail_basic/#{$bfile1}") { "BizMail Basic Information" }
        end + 
        $cgi.p do
          $cgi.a("bizmail_ext/#{$bfile2}") { "BizMail Extend Information"  } 
        end +
        $cgi.p do  
          $cgi.a("dneobackup/#{$dnfile}") { "desknets account for import"  }
        end +  
        $cgi.p do  
          $cgi.a("jobnet/#{$jbfile}") { "jobnet command file"  }
        end +  
        $cgi.p do  
          $cgi.a("anpi/#{$anpi_file}") { "anpi command file"  }
        end +  
        $cgi.pre() do
          CGI.escapeHTML(
            "params: " + $cgi.params.inspect + "\n" +
            "cookies: " + $cgi.cookies.inspect + "\n" +
            ENV.collect() do |key, value|
              aey + " --> " + value + "\n"
            end.join("")
          )
        end
      end
    end
  end
end

## list of domains we can handle... 
# $tdomains = [ "ray.co.jp","ss.ray.co.jp", "plays.co.jp", "digisite.co.jp","tc-max.co.jp","wes.co.jp"  ] 
$log = Logger.new('/var/log/ldap.log')
$log.level = Logger::WARN
$cgi = CGI.new("html4")
#$cgi = CGI.new("html5")

# Tracer.on
$domain = $cgi['domain']
$force = $cgi.params['force'][0]  

# puts "$domain #{$domain}" 

if $cgi['debug'] ==""  then 
  $DEBUG = "0"
else 
  $DEBUG = $cgi['debug']
end 
#$stderr_sv = STDERR.dup
#STDERR.reopen("/var/log/ruby/error.log")
# Tracer.off
# puts "Content-Type: text/html" 
if $DEBUG == "1" then  
## debug inputs 
  $mail= "postmaster"
  $domain = "digisite.co.jp"
  $shain = "123456" 
  $passwd = "ray12345"
  $mei="敦子"
  $sei="前田"
  $name="あつこ"
  $f_name="まえだ"
  $check = ""
elsif $DEBUG == "2" then 
#$mail = ARGV[0] 
  $mail   = $cgi['email'] 
  $domain = $cgi['domain']
  $shain  = $cgi['shain']
  $passwd = $cgi['passwd']
  $mei    = $cgi['mei']
  $sei    = $cgi['sei']
  $name   = $cgi['name']
  $f_name = $cgi['f_name']
  $check  = $cgi['check'] 
  $create = $cgi['create']
  $reset  = $cgi['reset']
else 
#$mail = ARGV[0] 
  $mail   = $cgi['email'] 
#  $domain = $cgi['domain']
  $shain  = $cgi['shain']
  $passwd = $cgi['passwd']
  $mei    = $cgi['mei']
  $sei    = $cgi['sei']
  $name   = $cgi['name']
  $f_name = $cgi['f_name']
  $check  = $cgi['check'] 
  $create = $cgi['create']
  $reset  = $cgi['reset']
end
$err = 0
if $result == nil then 
  $result = "_"
end 
## ignore domain from list. just use e-mail addr.
if (mad = $mail.split("@")) != nil then 
  $domain = mad[1]
  $uid = mad[0]
else 
  $err += 1 
  $result += "メールアドレスが不正です。"
end 

def getemail(sname, fname, shain)
  ff = Romaji.kana2romaji(fname)
  ss = Romaji.kana2romaji(sname)
  puts "#{ff}, #{ss}, #{shain}"  if $DEBUG != "0"  
  snum = shain.to_i
  # 社員番号からドメインを決定 
  case snum
  when 0..9999 
    dom = 'ray.co.jp'
  else 
    dom = 'ss.ray.co.jp' 
  end
  # oo -> o 
  mail_local = ss.sub( /oo/, "o")  
  mail = ff[0]  +"-"+  mail_local + "@" + dom 
  puts mail  if $DEBUG != "0" 
  return mail 
end

# input data validation
if Moji.type($name) == Moji::HAN_KATA  then 
  $name = Moji.han_to_zen($name)
  puts Moji.type($name) if $DEBUG != "0"
  puts $name if $DEBUG != "0" 
end
if Moji.type($name) == Moji::ZEN_KATA then 
  $name = Moji.kata_to_hira($name)
end 
if Moji.type($f_name) == Moji::HAN_KATA  then 
  $f_name = Moji.han_to_zen($f_name)
  $f_name = Moji.kata_to_hira($f_name)
  puts Moji.type($f_name) if $DEBUG != "0"
  puts $f_name if $DEBUG != "0" 
end
if Moji.type($f_name) == Moji::ZEN_KATA then 
  $f_name = Moji.kata_to_hira($f_name)
end 

ecnt = 0 
if (($mail == nil) || ($mail =="")) then 
  ## generate mail address based on naming convention
  if (($name == nil) || ($name =="")) then 
    $result += "姓のふりがなを入力してください。"
    ecnt += 1
  end   
  if $f_name == nil || $f_name =="" then 
    $result += "名のふりがなを入力してください。"
    ecnt += 1 
  end 
  if $shain == nil || $shain =="" then 
    $result += "社員番号を入力してください。"
    ecnt += 1
  end 
  if ecnt > 0 then 
    $result += "メールアドレスを指定してください．\n"
    $err +=1 
  else 
    $mail = getemail($f_name, $name, $shain)
    if $mail == nil || $mail.length < 4 then 
      $result += "ふりがなからアドレスを決定出来ませんでした。#{$f_name},#{$name},#{$shain}" 
      $err += 1
    else 
      bb = $mail.split('@')
      $domain = bb[1] 
    end 
  end 
end 
if $domain==nil || $domain =="" then 
  $result += "ドメインを指定してください．"
  $err += 1
end 
if $err > 0 then 
  exit_job
  exit -1 
end
#### db 
if $create.length > 1 then 
  $mode = 1   # Create mode
elsif $reset.length > 1 then 
  $mode = 2   # reset mode
  $mail = ""
  $domain = ""
  $shain = ""
  $passwd = "" 
  $mei = "" 
  $sei = ""
  $name =""
  $f_name =""
  $resk = "" 
  $result = "Reset Complete." 
  exit_job 
  exit 
else 
  $mode = 0   # check mode.
end

# create password if no password is given.
if $passwd == nil || $passwd.length < 8 then 
  $passwd = mkps8  # create new password 
  puts "password:#{$passwd}" if $DEBUG != "0" 
  $log.warn($passwd) 
end 
## check email address exists on ldap db.....
# puts "mail #{$mail}" 
#p $mail.length 
#p $mail.include?("@")
#p $mail.split("")
#p $mail.index('y')
# if /\@/  =~ $mail then  
$resk = "" 
# Check if given address is already taken? 
def adrcheck(mail) 
#  byebug 
  target = mail
  attr = "mail"  
  bb = mail.split('@')
  if bb != nil  then 
    domain = bb[1] 
    uid = bb[0]  
  else 
    puts "e-mail addres error." if $DEBUG != "0"  
    return 0 # true  
  end 
  # decide parameters for each ldap server 
  $ldap = getldap(mail)
#  puts "<#{$ldap}>"  
  case $ldap 
  when 'ldap.ray.co.jp' 
    $auth = { :method => :simple, :username => "cn=Manager,dc=ray,dc=co,dc=jp", :password => "ray00" }
    $host = 'ldap.ray.co.jp'
    $treebase = "ou=Mail,dc=ray,dc=co,dc=jp"
  when  'ldap2.ray.co.jp'
    $auth = { :method => :simple, :username => "cn=Manager,dc=ray,dc=jp", :password => "ray00" }
    $host = 'ldap2.ray.co.jp'
    $treebase = "ou=Mail,dc=ray,dc=jp"
  else 
    $result = "ドメイン #{domain}は未対応です。#{$ldap}"
    $mailok = false
    $host = nil 
    return
  end 
  if $host == nil || $host.length < 1 then  
    return 0
  else 
    hits=0
    $result = "not executed" 
  end 
  begin
    # check if mail address is already exists. 
    Net::LDAP.open(:host => $host ,:port => 389 , :auth => $auth  ) do |ldap|
    #  ,:encryption => :simple_tls # ldap.port = 389 636
      filter = Net::LDAP::Filter.eq( attr, target)
      p filter if $DEBUG != "0"  
      ldap.search(:base => $treebase, :filter => filter ) do |entry|
        puts entry if $DEBUG != "0" 
        uidc = 0
        hits+= 1
        $log.warn("DN: #{entry.dn}")
        entry.each do |attribute, values|
          if attribute == 'uid' then
            uidc += 1
            puts "<#{attribute}>" if $DEBUG != "0" 
          end
          print " #{attribute}:" if $DEBUG != "0" 
          values.each do |value|
            print "#{value}" if $DEBUG != "0" 
          end
          print "\n" if $DEBUG != "0" 
        end
        if uidc > 1 then
          $log.warn( "uid#{uidc}  error in #{entry.dn}")
          puts ( "uid#{uidc}  error in #{entry.dn}") if $DEBUG != "0"  
        end
      end
      $log.info(ldap.get_operation_result)
    end 
  rescue => ex
    $log.fatal( ex)
  end

  if hits > 0 then
    $mailok = false 
    $resk += "#{target}_is_already_exists.#{hits}"  
    return hits  
  else 
    $mailok = true 
    $resk +=  "#{target}_is_OK.#{hits}"  
    return hits 
  end
end  ## adrcheck end 
#byebug
r1=adrcheck($mail)
b1 = $mail.split('@')
if b1 != nil then 
  if b1[1] == 'ray.co.jp' then 
    mail2 = b1[0] + '@ss.ray.co.jp' 
  else 
    mail2 = b1[0] + '@ray.co.jp' 
  end
#  byebug 
  r2 =adrcheck(mail2) 
  # both @ray.co.jp & @ss.ray.co.jp is ok
  $resk += "  --  #{$mail}:#{r1}_#{mail2}:#{r2}"
  puts r1,r1.class, r2, r2.class if $DEBUG != "0"  
  if (r1 >0 || r2 > 0) then
    if ($force != 'on') then 
      exit_job 
    else
      $mailok = true  
      $result += "\t r1:#{r1},r2:#{r2},force:#{$force}" 
#      exit_job 
    end 
  else 
    $result += "\t r1:#{r1},r2:#{r2},force:#{$force}" 
    # continue to create data  exit_job  
  end 
else 
  $result += "#{$mail} address error!" 
  exit_job 
end   
puts "continue to create data...." if $DEBUG != "0"  

puts "$mail: #{$mail} $domain: #{$domain} $host: #{$host}" if $DEBUG != "0" 
if ($mode == 1) && $mailok then  
  ## set ldap data 
  $host = getldap($mail) 
  bb = $mail.split('@') 
  if bb != nil then 
    $uid = bb[0]
    $domain = bb[1]
  end 
  puts "#{$uid},#{$uid1},#{$domain},#{$domain1}" if $DEBUG != "0"  
  # pop account : a-arakawa
  if $domain == 'ray.co.jp' then 
    $domain1 = '' 
    $uid1 = $uid 
  else
    $domain1 = $domain 
  end 
  if ($host == 'ldap2.ray.co.jp')  then
    $uid1 = $mail 
    dn = "uid=#{$uid1},ou=Mail,dc=ray,dc=jp"
    attr = {
     :objectClass =>  "mailUser" ,
     :cn => $sei+$mei,
     :sn => $sei, 
     :uid => $uid1, 
     :givenName => $f_name + "　" + $name , 
     :employeeNumber => $shain, 
     :userPassword => $passwd,  
     :homeDirectory => "/data/home/vmail/#{$domain}/#{$uid}" ,
     :mailDir => "#{$domain}/#{$uid}/Maildir/",
     :mail => $mail ,
     :mailQuota => '256' , 
     # skip wifiuid ,  AccountKind 
     :accountActive => "TRUE",
     :domainName => $domain,  
     :transport => 'virtual'
    }
  else 
    if $domain == 'ray.co.jp' then 
      $uid1 = $uid
    else 
      $uid1 = $mail
    end 
    dn = "uid=#{$uid1},ou=Mail,dc=ray,dc=co,dc=jp"
    attr = {
     :objectClass =>  "mailUser" ,
     :cn => $sei+$mei,
     :sn => $sei, 
     :uid => $uid1, 
     :givenName => $f_name + "　" + $name , 
     :employeeNumber => $shain, 
     :userPassword => $passwd,  
     :homeDirectory => "/data/home/vmail/#{$domain}/#{$uid}" ,
     :mailDir => "#{$domain}/#{$uid}/Maildir/",
     :mail => $mail ,
     :mailQuota => '256' , 
     :accountKind => '1',
     :wifiuid => $mail ,
     :accountActive => "TRUE",
     :domainName => $domain,  
#     :transport => 'virtual'
     :transport => 'smtp:[vcgw1.ocn.ad.jp]'
    }
  end 
#  p attr 
## print ldif 
  
  $ldif  = sprintf "dn: #{dn}\n"  
  $ldif += sprintf "objectClass: mailUser\n"
  $ldif += sprintf "cn: #{$sei}#{$mei}\n"
  $ldif += sprintf "sn: #{$sei}\n" 
  $ldif += sprintf "uid: #{$uid1}\n" 
  $ldif += sprintf "employeeNumber: #{$shain}\n" 
  $ldif += sprintf "userPassword: #{$passwd}\n"   
  $ldif += sprintf "homeDirectory: /data/home/vmail/#{$domain}/#{$uid}\n"
  $ldif += sprintf "mailDir: #{$domain}/#{$uid}/Maildir/\n"
  $ldif += sprintf "mail: #{$mail}\n"
  $ldif += sprintf "mailQuota: 256\n" 
  unless ($host == 'ldap2.ray.co.jp ') then 
    $ldif += sprintf "accountKind: 1\n"
    $ldif += sprintf "wifiuid: #{$mail}\n"
  end
  $ldif += sprintf "accountActive: TRUE\n"
  $ldif += sprintf "domainName: #{$domain}\n"   
  if ($host == 'ldap2.ray.co.jp') then 
    $ldif += sprintf "transport: virtual\n"
  else 
    $ldif += sprintf "transport: smtp:[vcgw1.ocn.ad.jp]\n"
  end 
  File.write( "./ldifbackup/" +$mail,$ldif) 
## print dnet csv
  $dnet = sprintf ("0,0,")
  $dnet += sprintf("#{$sei}　#{$mei},#{$f_name}　#{$name},#{$shain},#{$passwd},#{$mail},,,,,,,,,,,,,,,,,,,,"",ja_JP,JST,期間外,,*360\n" )
  $dnfile = $mail + "_dneo.csv" 
  dnet_s = sjis_conv($dnet) 
  File.write( "./dneobackup/" +$dnfile, dnet_s ) 
## File to set JOBNET .Xpoint, Anpi  shain name kana email password dept proto-name 入社日
  $jobnet =  sprintf ("ruby jobnet.rb #{$shain} #{$sei}　#{$mei} #{$f_name}　#{$name} #{$mail} #{$passwd} 管理本部/業務研修 ダミー　太郎 2018/04/01\n")
  jnet_s = sjis_conv($jobnet)
  $jbfile = $mail + "_jobnet.csv" 
  File.write("./jobnet/" + $jbfile, jnet_s) 
  anpi_com = sprintf("ruby anpi.rb #{$shain} #{$sei}　#{$mei} #{$f_name}　#{$name} #{$mail} 東京都\n")
  anpi_s = sjis_conv(anpi_com) 
  $anpi_file = $mail + "_anpi.csv" 
  File.write( "./anpi/" + $anpi_file, anpi_s )
  ## output file for biz mail 
#  puts "Written #{$mail}, #{$dnfile}"  
#  exit  
#  Biz mail 一括登録基本情報
#  email, グループ名、姓、姓（ふりがな）、名、名（ふりがな）、パスワード、アカウントステータス(0),管理者権限(0)
 
  fn = Moji.hira_to_kata($f_name)
  nm = Moji.hira_to_kata($name) 
  bas = "#{$mail},ユーザー,#{$sei},#{fn},#{$mei},#{nm},#{$passwd},0,0\n"
#  p bas  
#  bas_s = sjis_conv(bas)
  bas_s = bas.encode("Shift_JIS") 
  $bfile1 = $mail + ".csv" 
  File.write("./bizmail_basic/" + $bfile1 , bas_s)
  #       mail    ,  group,  sn,  shain ,    cn ,   desc          pass           
# アカウント詳細情報（変更）
# email, 表示名、Middle,global連動(0), PW変更(0), 説明、備考、郵便番号、都道府県、市町村、住所、国、会社、会社（フリガナ）、役職、電話番号、自宅電話、携帯、ポケットベル、FAX、メールをHTMLで表示(0)、HTHMLメールに外部イメージを表示(0)、新着メール通知アドレスを有効に(0)、新着通知メールアドレス、自動返信メッセージ有効、メール送信許可アドレス１、メール送信許可アドレス２、メール送信許可アドレス３、設定不要、設定不要、転送設定有効、作成メール形式(0:text,1:html)、UIテーマ、メッセ維持のコピーをBOXに残さない、IMAP有効(1),IMAP検索フォルダを表示(0), TZ077,5,0,0,0  
# 1- 41  
  ext = "#{$mail},#{$sei}　#{$mei},,0,0,,#{$shain},,,,,,,,,,,,,,1,1,0,,0,,,,,,0,1,beach,0,1,0,TZ077,5,0,0,0,0\n" 
#  ext_s = sjis_conv(ext) 
  ext_s = ext.encode("Shift_JIS")  
  $bfile2 = $mail + "_ext.csv" 
  File.write("./bizmail_ext/" + $bfile2 , ext_s)
## bizmail end
## add entry to ldap
  puts $host if $DEBUG != "0" 
#  byebug 
  Net::LDAP.open(:host => $host ,:port => 389 , :auth => $auth  ) do |ldap|
    #  ,:encryption => :simple_tls # ldap.port = 389 636
    #    p filter
    p dn if $DEBUG != "0"  
    p attr if $DEBUG != "0" 
    ldap.add( :dn => dn, :attributes => attr ) 
    p ldap.get_operation_result  if $DEBUG != "0"#  .code 
    $result = ldap.get_operation_result.to_s  #  .code 
  end
  exit_finish
else 
  exit_job
  exit 
end 
