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

# check and create 
# todo 
# check local part for @ray.co.jp and @ss.ray.co.jp 
# $DEBUG = 9 
def exit_job
  
  if $mail && ($mail.index('@') == nil) then 
    begin 
      p $mail
      p $domain
      p $result 
    end if $DEBUG
    $result += "Email Address Error!#{$mail}"  
  end 
#    if $domain != nil then 
#      $mail += '@' 
#      $mail += $domain
#      puts "mail :#{$mail}" if $DEBUG  
#    end   
  redirect_url = 'mchk.rhtml' + '?' + "result=#{$result}&email=#{$mail}&domain=#{$domain}&shain=#{$shain}&passwd=#{$passwd}&mei=#{$mei}&sei=#{$sei}&name=#{$name}&f_name=#{$f_name}" 

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
        $cgi.pre() do
          CGI.escapeHTML(
            "params: " + $cgi.params.inspect + "\n" +
            "cookies: " + $cgi.cookies.inspect + "\n" +
            ENV.collect() do |key, value|
              key + " --> " + value + "\n"
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
# puts "$domain #{$domain}" 

if $cgi['debug'] ==""  then 
  $DEBUG = false
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
# if (($domain =="") || ($domain == 'ray.co.jp')) then
  # $uid をローカル部だけに。
#  if ((mad = $mail.split("@")) != nil) then 
#    $uid = mad[0]
  #  $domain = mad[1]
#  else 
#    $err +=1 
#    $result  += "メールアドレスエラー"
#  end
# else 
#  $uid = $mail 
# end 
# puts "mail #{$mail}, domain #{$domain} " 

def getemail(sname, fname, shain)
  ff = Romaji.kana2romaji(fname)
  ss = Romaji.kana2romaji(sname)
  puts "#{ff}, #{ss}, #{shain}"  if $DEBUG  
  snum = shain.to_i 
  case snum
  when 0..9999 
    dom = 'ray.co.jp'
  else 
    dom = 'ss.ray.co.jp' 
  end 
  mail = ff[0] +"-"+  ss + "@" + dom 
  puts mail  if $DEBUG
  return mail 
end

if Moji.type($name) == Moji::HAN_KATA  then 
  $name = Moji.han_to_zen($name)
  puts Moji.type($name) if $DEBUG
  puts $name if $DEBUG 
end
if Moji.type($name) == Moji::ZEN_KATA then 
  $name = Moji.kata_to_hira($name)
end 
if Moji.type($f_name) == Moji::HAN_KATA  then 
  $f_name = Moji.han_to_zen($f_name)
  $f_name = Moji.kata_to_hira($f_name)
  puts Moji.type($f_name) if $DEBUG
  puts $f_name if $DEBUG
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
  $result = "Reset Complete." 
  exit_job 
  exit 
else 
  $mode = 0   # check mode.
end
if $passwd == nil || $passwd.length < 8 then 
  $passwd = mkps8  
  puts "password:#{$passwd}" if $DEBUG
  $log.warn($passwd) 
end 
## check email address exists on ldap db.....
# puts "mail #{$mail}" 
#p $mail.length 
#p $mail.include?("@")
#p $mail.split("")
#p $mail.index('y')
# if /\@/  =~ $mail then  

# Check if given address is already taken? 
def adrcheck(mail) 
  target = mail
  attr = "mail"  
  bb = mail.split('@')
  if bb != nil  then 
    domain = bb[1] 
    uid = bb[0]  
  else 
    puts "e-mail addres error." if $DEBUG  
    return true  
  end 
  # decide parameters for each ldap server 
  ldap = getldap(mail)
  case ldap 
  when 'ldap.ray.co.jp' 
    $auth = { :method => :simple, :username => "cn=Manager,dc=ray,dc=co,dc=jp", :password => "ray00" }
    $host = 'ldap.ray.co.jp'
    $treebase = "ou=Mail,dc=ray,dc=co,dc=jp"
  when 'wm2.ray.co.jp' 
    $auth = { :method => :simple, :username => "cn=Manager,dc=ray,dc=jp", :password => "1234" }
    $host = 'wm2.ray.co.jp'
    $treebase = "ou=Mail,dc=ray,dc=jp"
  else 
    $result = "ドメイン #{domain}は未対応です。"
    $mailok = false
    $host = nil 
    return true 
  end 
  if $host.length < 1 then  
    return true 
  else 
    hits=0
    $result = "not executed" 
  end 
  begin
    # check if mail address is already exists. 
    Net::LDAP.open(:host => $host ,:port => 389 , :auth => $auth  ) do |ldap|
    #  ,:encryption => :simple_tls # ldap.port = 389 636
      filter = Net::LDAP::Filter.eq( attr, target)
      p filter if $DEBUG 
      ldap.search(:base => $treebase, :filter => filter ) do |entry|
        puts entry if $DEBUG
        uidc = 0
        hits+= 1
        $log.warn("DN: #{entry.dn}")
        entry.each do |attribute, values|
          if attribute == 'uid' then
            uidc += 1
            puts "<#{attribute}>" if $DEBUG
          end
          print " #{attribute}:" if $DEBUG
          values.each do |value|
            print "#{value}" if $DEBUG
          end
          print "\n" if $DEBUG 
        end
        if uidc > 1 then
          $log.warn( "uid#{uidc}  error in #{entry.dn}")
          puts ( "uid#{uidc}  error in #{entry.dn}") if $DEBUG 
        end
      end
      $log.info(ldap.get_operation_result)
    end 
  rescue => ex
    $log.fatal( ex)
  end

  if hits > 0 then
    $mailok = false 
    $result = "#{target}_is_already_exists.#{hits}"  
    return hits  
  else 
    $mailok = true 
    $result = "" #  "#{target}_is_OK.#{hits}"  
    return hits 
  end
end  ## adrcheck end 

if (r1=adrcheck($mail)) == 0 then 
  b1 = $mail.split('@')
  if b1 != nil then 
    if b1[1] == 'ray.co.jp' then 
      mail2 = b1[0] + '@ss.ray.co.jp' 
    else 
      mail2 = b1[0] + '@ray.co.jp' 
    end 
    if (r2 =adrcheck(mail2)) == 0 then 
      # both @ray.co.jp & @ss.ray.co.jp is ok
      $result += "#{$mail}:#{r1}_#{mail2}:#{r2}"
    else 
      exit_job  
    end 
  else 
    $resutl += "#{$mail} address error!" 
    exit_job 
  end   
else
  exit_job 
end    
 
# puts "$mail: #{$mail} $domain: #{$domain} $host: #{$host}" 
if ($mode == 1) && $mailok then  
  ## set ldap data 
  $host = getldap($mail) 
  bb = $mail.split('@') 
  if bb != nil then 
    $uid = bb[0]
    $domain = bb[1]
  end 
  puts "#{$uid},#{$uid1},#{$domain},#{$domain1}" if $DEBUG  
  # pop account : a-arakawa
  if $domain == 'ray.co.jp' then 
    $domain1 = '' 
    $uid1 = $uid 
  else
    $domain1 = $domain 
  end 
  if $host == 'wm2.ray.co.jp'  then
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
     :transport => 'virtual'
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
  unless $host == 'wm2.ray.co.jp' then 
    $ldif += sprintf "accountKind: 1\n"
    $ldif += sprintf "wifiuid: #{$mail}\n"
  end
  $ldif += sprintf "accountActive: TRUE\n"
  $ldif += sprintf "domainName: #{$domain}\n"   
  $ldif += sprintf "transport: virtual\n"
  File.write( "./ldifbackup/" +$mail,$ldif) 
## print dnet csv
  $dnet = sprintf ("0,0,")
  $dnet += sprintf("#{$sei}　#{$mei},#{$f_name}　#{$name},#{$shain},#{$passwd},#{$mail},,,,,,,,,,,,,,,,,,rg1099," )

  File.write( "./dnetbackup/" +$mail+".csv",$dnet) 
  ## add entry to ldap 
  Net::LDAP.open(:host => $host ,:port => 389 , :auth => $auth  ) do |ldap|
    #  ,:encryption => :simple_tls # ldap.port = 389 636
    #    p filter
    p dn if $DEBUG 
    p attr if $DEBUG
    ldap.add( :dn => dn, :attributes => attr ) 
    p ldap.get_operation_result  if $DEBUG #  .code 
    $result = ldap.get_operation_result.to_s  #  .code 
  end
  exit_finish
else 
  exit_job
  exit 
end  