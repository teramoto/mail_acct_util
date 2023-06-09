#!/usr/local/bin/ruby
# encoding : utf-8 

require 'net/ldap'
require 'logger'
require 'mail' 
require 'nkf' 

MAX_WID = 3 
BASE_PATH = "/var/www/html/foundation-4/regist/"
ISSUE_PATH = BASE_PATH + "issued/"
REC_PATH = BASE_PATH + "wifirecord/" 
EXP_PATH = BASE_PATH + "expired/" 
FIN_PATH = BASE_PATH + "wifirecord.fin/"
 
# $tdomain = [ "ray.co.jp", "plays.co.jp", "digisite.co.jp", "wbc-dvd.com", "tera.nu", "tc-max.co.jp" ]
$tdomain = [ "ray.co.jp", "plays.co.jp", "digisite.co.jp", "wbc-dvd.com", "tera.nu" ]

#-
# Generate ldif 
#++
def genldif(wid, name, pass, email, sn, gn, dpt, since, tuntil)
  if $deb then
    return
  end
  open("wifildif/#{wid}", "w") do |file|
    file.puts "dn: uid=#{wid},ou=Services,dc=ray,dc=co,dc=jp"
    file.puts "objectClass: wifiUser"
    file.puts "uid: #{wid}"
    file.puts "cn: #{name}"
    file.puts "userPassword: #{pass}"
    file.puts "mail: #{email}"
    file.puts "sn: #{sn}"
    file.puts "givenName: #{gn}"
    file.puts "departmentNumber: #{dpt}"
    file.puts "domainName: ray.co.jp"
    file.puts "accountActive: TRUE"
    file.puts "wifiuid: #{wid}"
  end
  log = Logger.new('/var/log/wifiguest.log')
  log.level = Logger::INFO
  `ldapadd -x -D cn=Manager,dc=ray,dc=co,dc=jp -w ray00 -f \"wifildif//#{wid}\" -h ldap.ray.co.jp`
  res = $?.to_s.split(' ')
  if !((res[2] == 'exit') && (res[3] =='0')) then
    log.error("#{wid}: #{$?}")
    return -1
#    puts $?
  else
    auth = { :method => :simple, :username => "cn=Manager,dc=ray,dc=co,dc=jp", :password => "ray00" }
    hits =0
    result = "not executed"
## due to unkonwn reason, ldap.add with wifiUser (original schema) is not added..
#    Net::LDAP.open(:host =>'ldap.ray.co.jp',:port => 389 , :auth => auth  ) do |ldap|
#     ,:encryption => :simple_tls # ldap.port = 389 636
    dn = "uid=#{wid},ou=Services,dc=ray,dc=co,dc=jp"
#    attr = {
#      :objectClass => [ "top" , "inetorgperson", "mailuser",  "wifiuser" ] ,
#      :uid => wid,
#      :cn => name,
#      :userPassword => pass,
#      :mail =>email,
#      :sn => sn,
#      :givenName => gn,
#      :departmentNumber => dpt,
#      :accountActive => "TRUE",
#      :wifiuid => wid,
#    }
    log.info ("Adding #{dn} ")
#    begin
#      ldap.add(:dn => dn, :attributes  => attr )
#      puts ldap.get_operation_result
#      log.info(ldap.get_operation_result)
#    rescue => ex
#      p ex
#    end
     return 0
  end
end
## end of genldif function

#-
# Generate ldif fo group users 
#++
def genldifgr(wid, name, pass, email, sn, gn, dpt, since, tuntil)
  if $deb then
    return
  end
  open("wifildif/#{wid}", "w") do |file|
    file.puts "dn: uid=#{wid},ou=Services,dc=ray,dc=co,dc=jp"
    file.puts "objectClass: wifiUser"
    file.puts "uid: #{wid}"
    file.puts "cn: #{name}"
    file.puts "userPassword: #{pass}"
    file.puts "mail: #{email}"
    file.puts "sn: #{sn}"
    file.puts "givenName: #{gn}"
    file.puts "departmentNumber: #{dpt}"
    file.puts "domainName: ray.co.jp"
    file.puts "accountActive: TRUE"
    file.puts "wifiuid: #{wid}"
  end
  log = Logger.new('/var/log/wifigr.log')
  log.level = Logger::INFO
#  `ldapadd -x -D cn=Manager,dc=ray,dc=co,dc=jp -w ray00 -f \"wifildif//#{wid}\" -h ldap.ray.co.jp`
#  res = $?.to_s.split(' ')
#  if !((res[2] == 'exit') && (res[3] =='0')) then
#    log.error("#{wid}: #{$?}")
#    return -1
#    puts $?
#  else
    auth = { :method => :simple, :username => "cn=Manager,dc=ray,dc=co,dc=jp", :password => "ray00" }
    hits =0
    result = "not executed"
## due to unkonwn reason, ldap.add with wifiUser (original schema) is not added..
    Net::LDAP.open(:host =>'ldap.ray.co.jp',:port => 389 , :auth => auth  ) do |ldap|
    #     ,:encryption => :simple_tls # ldap.port = 389 636
    dn = "uid=#{wid},ou=Services,dc=ray,dc=co,dc=jp"
    attr = {
#      :objectClass => [ "top" , "inetorgperson", "mailuser",  "wifiuser" ] ,
      :objectClass =>  "wifiuser" ,
      :uid => wid,
      :cn => name,
      :userPassword => pass,
      :mail =>email,
      :sn => sn,
      :givenName => gn,
      :departmentNumber => dpt,
      :domainName => 'ray.co.jp', 
      :accountActive => "TRUE",
      :wifiuid => wid 
    }
    begin
      ldap.add(:dn => dn, :attributes  => attr )
      puts ldap.get_operation_result if $deb
      log.info(ldap.get_operation_result)
    rescue => ex
      p ex if $deb
    end
    return 0
  end
end

def sendm( toaddr, dept, mes )
  case dept
  when 1100
    attch = "MCDVD"
  when 1101
    attch = "MCVS"
  when 1026
    attch = "RAY"
  when 1028
    attch = "WES"
  when 1029
    attch = "TCMax"
  when 1030
    attch = "TCSP"
  when 20001
    attch = "GUEST"
  when 1027
    
  else
    puts "Attachment error!" if $DEBUG
    exit
  end
  attch = attch + ".mobileconfig"
  puts "attachmeit file = #{attch}" if $DEBUG
  puts  toaddr if $DEBUG
#  p "mes = #{mes}"   
  mess1 = mes.join("\n")
  p mess1 if $DEBUG
  mail = Mail.new
  mail.charset = 'ISO-2022-JP'
  mail.from = 'RayGroup Networkteam<noreply@ray.co.jp>'
  if $DEBUG then
    mail.to = 'ken@ray.co.jp'
  else
    mail.to   = toaddr
  end
  if $cc && $cc.length > 2 then
    mail.cc = $cc + ',networkteam@ray.co.jp'
  else
    mail.cc   = 'networkteam@ray.co.jp'
  end
  mail.subject = 'レイ・グループWifi設定完了のお知らせ'
  mail.body  =  NKF.nkf('-Wj', mess1).force_encoding("ASCII-8BIT")
  mail.add_file(attch)
  mail.parts[0].charset = 'ISO-2022-JP'
#  mail.attachments[attch] = File.read(attch)
#  p mail.to_s
  mail.deliver
end

### dept2ssid 
def dept2ssid(dept) 
  case dept.to_i
  when 1026 # 管理本部
    ssid = "RGHARKSRPGSS"
  when 1028 # WES
    ssid = "RGHARKSRPGWB"
  when 1029 # TC-Max 
    ssid = "RGHARKSRPGTA" 
  when 1030 # TC-Max SP 
    ssid = "RGHARKSRPGTS" 
  when 1100 # mcray DVD
    ssid = "RGHARKSMCDVD"
  when 1101 # mcray VS
    ssid = "RGHARKSMCVS"
  when 20001 # guest
    ssid = "RAYGROUPGUEST"
  else
    puts "undefined department!" if $DEBUG
    ssid = "" 
  return ssid 
  end
end

### build messdage body
def buildmessage( toname,id,passwd, dept )
  mes = Array.new()
  ssid = dept2ssid(dept)
  if (ssid =="") then 
    puts "undefined department!" if $DEBUG
  end
  wifi = "IEEE802.11\/g,\/b,\/n"
  puts wifi if $DEBUG

  mes.push("#{toname}様")
  mes.push("レイ・グループWifi接続用のIDとパスワードをお知らせします。")
  mes.push("ログインID：#{id}")
  mes.push("パスワード：#{passwd}")
  mes.push("接続手順：")
  mes.push ("アクセスポイントは#{wifi}の無線LAN規格に対応しています。")
  
  if dept < 20000 then 
    mes.push("セキュリティでWPA2(パーソナル）を選び、SSIDとパスフレーズを入力して接続してください。")
    mes.push(" (ステルスモードで運用しています。ブラウジング画面にSSIDは表示されませんので入力が必要です。）")
  else 
    mes.push("SSID :#{ssid}、セキュリティー:WPA2パーソナルを選んでパスワードを入力してください。")
  
  end 
  mes.push("詳しくは　http://it.ray.co.jp/html/wifi/ をご参照ください。")

  mes.push("") 
  mes.push("SSID    :#{ssid}")
  mes.push("Password:#{ssid}")
  ttk = <<"EOS"

接続確認後、ブラウザーを起動して任意のURL(http://www.yahoo.co.jp/ 等)をアクセスして下さい。
システムのログイン画面が表示されますので、ＩＤとパスワードを入力してください。
認証が完了するとネットワークのアクセスができるようになります。
５分間程度通信が行われないと接続が切れてしまい、再度ブラウザーでの認証が必要になります。
通信が切れた場合はウェブブラウザーで通信状態を確認してください。
PCがスリープ状態になった場合、電波が届かないところに行った場合も接続が切れますので、
使用時に再接続をして下さい。
    
※システムはハークスビルの１階、３階、４階で使用可能です。
※アクセスポイント間で移動した場合はローミングを行います。
※遠いアクセスポイントに接続していると速度が遅くなる場合があります。
このようなときは一度切断して再接続した方がよい場合もあります。
スマートフォン、携帯電話等のデバイスも同様に接続できます
iOS機器をご利用の方は添付の構成プロファイルをインストールすると
簡単に接続できますので
ご利用ください。
御質問等ございましたら株式会社レイ・ネットワーク課までお願いいたします。
EOS
  mes.push(ttk) 
  return mes 
end

def check_issued(email)
  pass1 = ISSUE_PATH + "#{email}"
#  puts  pass1 
  cnt = 0 
  if File.exist?( pass1 )  then
#    puts "File #{pass1} exist!" 
    # open file and count wid number...
    begin 
      lines = File.read(pass1) 
#      p lines 
      l = lines.split("\n")
#      p l 
      l.each do |l1|  
#        p l1 
        m = l1.split(',')
#        p m[4]
        if m[4] == email then 
          cnt += 1    
        end 
      end
    rescue => ex 
      p $! 
      p ex 
    end 
#    puts cnt  
    return cnt
  else 
#    puts "email #{pass1} does not exists..."
    return 0  
  end 
end

def wldapvalue(attr, val, ndattr) ## ou= Services
  log = Logger.new('/var/log/wifiguest.log')
  log.level = Logger::INFO
  auth = { :method => :simple, :username => "cn=Manager,dc=ray,dc=co,dc=jp", :password => "ray00" }
  hits =0
  result = "not executed" 
#  begin
    Net::LDAP.open(:host =>'ldap.ray.co.jp',:port => 389 , :auth => auth  ) do |ldap|
    #  ,:encryption => :simple_tls # ldap.port = 389 636
      filter = Net::LDAP::Filter.eq( attr, val)
#    p filter
      treebase = "ou=Services,dc=ray,dc=co,dc=jp"
      ldap.search(:base => treebase, :filter => filter ) do |entry|
#        puts "search result:#{entry}" 
        hits+= 1
        if ndattr == "DN" then
##          log.warn("wldapvalue: #{ndattr}:DN: #{entry.dn}" )
          return entry.dn
        end
##        log.warn("wldapvalue: DN: #{entry.dn} #{entry[ndattr][0]}")
        return entry[ndattr][0]
      end
##      log.info(ldap.get_operation_result)
    end
    if hits == 0 then 
      return nil 
    else 
      return false
    end
#  rescue => ex
#    log.fatal( ex)
#    return true 
#  end
end

def wldapvalueM(attr, val, ndattr) ## ou= Services
  log = Logger.new('/var/log/wifiguest.log')
  log.level = Logger::INFO
  auth = { :method => :simple, :username => "cn=Manager,dc=ray,dc=co,dc=jp", :password => "ray00" }
  hits =0
  result = "not executed" 
#  begin
    res = Array.new 
    Net::LDAP.open(:host =>'ldap.ray.co.jp',:port => 389 , :auth => auth  ) do |ldap|
    #  ,:encryption => :simple_tls # ldap.port = 389 636
      filter = Net::LDAP::Filter.eq( attr, val)
#    p filter
      treebase = "ou=Services,dc=ray,dc=co,dc=jp"
      ldap.search(:base => treebase, :filter => filter ) do |entry|
#        puts "search result:#{entry}" 
        hits+= 1 # entry.size
        res.push(entry) 
#        return entry
      end
##      log.info(ldap.get_operation_result)
    end
    if hits == 0 then 
      return nil 
    else 
      return res 
    end
#  rescue => ex
#    log.fatal( ex)
#    return true 
#  end
end

 
def whasattr(uid,attr)
  log = Logger.new('/var/log/wifiguest.log')
  log.level = Logger::WARN
  auth = { :method => :simple, :username => "cn=Manager,dc=ray,dc=co,dc=jp", :password => "ray00" }
  hits =0
  result = "not executed" 
  begin
    Net::LDAP.open(:host =>'ldap.ray.co.jp',:port => 389 , :auth => auth  ) do |ldap|
    #  ,:encryption => :simple_tls # ldap.port = 389 636
      filter = Net::LDAP::Filter.eq( 'uid', uid)
#    p filter
      treebase = "ou=Services,dc=ray,dc=co,dc=jp"
      ldap.search(:base => treebase, :filter => filter ) do |entry|
#      puts entry
        hits+= 1
        return entry[attr][0]
      end
##      log.info(ldap.get_operation_result)
    end
  rescue => ex
    log.fatal( ex)
    return true 
  end
end

def wgetpass(email )
  return ldapvalue( 'wifiuid', email , 'userPassword')
end

def wgetname(email )
  return ldapvalue( 'wifiuid', email , 'cn')
end

def wgetgname(email )
  return ldapvalue( 'mail', email , 'givenName')
end

def waddattr(uid, attr, value) 
  log = Logger.new('/var/log/wifiguest.log')
  log.level = Logger::WARN
  oplog = Logger.new('/var/log/wifiguestop.log')
  oplog.level = Logger::INFO
  auth = { :method => :simple, :username => "cn=Manager,dc=ray,dc=co,dc=jp", :password => "ray00" }
  hits =0
  result = "not executed"
  Net::LDAP.open(:host =>'ldap.ray.co.jp',:port => 389 , :auth => auth  ) do |ldap|
  #  ,:encryption => :simple_tls # ldap.port = 389 636
    filter = Net::LDAP::Filter.eq('uid', uid)
#  p filter
    treebase = "ou=Services,dc=ray,dc=co,dc=jp"
    $resdn = ""
    ldap.search(:base => treebase, :filter => filter ) do |entry|
#      if entry.length > 1 then
#        log.warn("fwedit: entry size =#{entry.size}")
#      end
#    puts entry
      $resdn = entry.dn
    end

    result = ldap.replace_attribute($resdn, attr, value)
    return result 
  end
  oplog.warn("addattr :DN: #{$resdn}: #{attr} : #{value} ")
end

def wldapdel(dn)
  log = Logger.new('/var/log/wifiguest.log')
  log.level = Logger::INFO
  oplog = Logger.new('/var/log/wifiguestop.log')
  oplog.level = Logger::INFO
  auth = { :method => :simple, :username => "cn=Manager,dc=ray,dc=co,dc=jp", :password => "ray00" }
  hits =0
  result = "not executed"
#  puts "dn = #{dn}"
  begin
    Net::LDAP.open(:host =>'ldap.ray.co.jp',:port => 389 , :auth => auth  ) do |ldap|
      result = ldap.delete :dn => dn
#      puts result
      puts ldap.get_operation_result if $DEBUG 
      oplog.info("#{dn} deleted,")
      return result
    end
  rescue => ex
    log.fatal( ex)
    return true
  end
end

def wldapdelgr(wifiuid)
  log = Logger.new('/var/log/wifigr.log')
  log.level = Logger::INFO
  oplog = Logger.new('/var/log/wifigrop.log')
  oplog.level = Logger::INFO
  auth = { :method => :simple, :username => "cn=Manager,dc=ray,dc=co,dc=jp", :password => "ray00" }
  hits =0
  dn = wldapvalue('wifiuid', wifiuid, 'dn') 
#  p dn if $deb 
  result = "not executed"
  puts "dn = #{dn}" if #deb 
  begin
    Net::LDAP.open(:host =>'ldap.ray.co.jp',:port => 389 , :auth => auth  ) do |ldap|
      dn = wldap
      result = ldap.delete :dn => dn
#      puts result
      puts ldap.get_operation_result if $DEBUG 
      oplog.info("#{dn} deleted,")
      return result
    end
  rescue => ex
    log.fatal( ex)
    return true
  end
end

