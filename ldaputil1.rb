#!/usr/local/bin/ruby
# encoding : utf-8 

require 'net/ldap'
require 'logger'
require 'tracer' 

#  handled by smtp.ray.co.jp
$tdomain = [ "ray.co.jp", "plays.co.jp", "digisite.co.jp", "wbc-dvd.com", "tera.nu", "tc-max.co.jp"  ]
# handled by sakura server www16276uf.sakura.ne.jp
$udomain = [ "ss.ray.co.jp" , "nissayseminar.jp", "nissayspeech.jp", "mcray.jp", "lic.prent.jp" ]
$vdomain = [ "wes.co.jp" ]  # web areana 
$wdomain = [ "tc-max.co.jp" ] 
$cdomain = [ "ray.co.jp" , "digisite.co.jp", "plays.co.jp" ]
#
#get ldap host from email  
def getldap( email )  
  if email == nil then 
    return true 
  end 
  ld = email.split('@')
  if ld == nil then 
    puts "invalid email #{email}" 
    return true 
  end 
  if $tdomain.index(ld[1]) then
    return  'ldap.ray.co.jp'
  elsif $udomain.index(ld[1]) then
    return  'wm2.ray.co.jp'
  end 
end

# mode = 1 : create, 2 : reset 
def ldapout(uid, mail, passwd, sei, mei, domain, f_name, name, shain , actkind, traddr)

  wrok = true  # control output to ldif database 
  mode = 1 
  if (mail.index('@') != nil)  then 
    puts ("mail should not be with domain.(#{mail})" )
    exit (-1)
  end 
  log = Logger.new('/var/log/ldap.log')
  log.level = Logger::WARN

  if (passwd == nil) || (passwd.length < 6) then 
    passwd = mkps8  
    puts "password:#{passwd}" if $DEBUG
    log.warn(passwd) 
  end 
  ## check email address exists on ldap db.....
  attr = "mail"
  target = mail + "@" + domain

  puts target if $DEBUG
  if $tdomain.index(domain) != nil && mode !=2  then 
    auth = { :method => :simple, :username => "cn=Manager,dc=ray,dc=co,dc=jp", :password => "ray00" }
    hits=0
    if domain == "tc-max.co.jp" then 
      puts ("Warning! #{domain} support is under development.")
    end 
    result = "not executed" 
    begin
      Net::LDAP.open(:host =>'ldap.ray.co.jp',:port => 389 , :auth => auth  ) do |ldap|
      #  ,:encryption => :simple_tls # ldap.port = 389 636
        filter = Net::LDAP::Filter.eq( attr, target)
        p filter if $DEBUG 
        treebase = "ou=Mail,dc=ray,dc=co,dc=jp"
        ldap.search(:base => treebase, :filter => filter ) do |entry|
          puts entry if $DEBUG
          uidc = 0
          hits+= 1
          log.warn("DN: #{entry.dn}")
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
            log.warn( "uid#{uidc}  error in #{entry.dn}")
            puts ( "uid#{uidc}  error in #{entry.dn}") if $DEBUG 
          end
        end
      log.info(ldap.get_operation_result)
      end
    rescue => ex
      log.FATAL( ex)
    end
    if hits > 0 then
      mailok = false 
      result = "#{target}_is_already_exists.#{hits}"  
    else 
      mailok = true 
      result = "#{target}_is_OK.#{hits}"  
    end
  else 
    result = "Cannot handle #{domain} with this version. Please ask Admin." 
    mailok = false
  end

  if (mode == 1) && mailok then  
    ## set ldap data 
    # pop account : a-arakawa
    if domain == 'ray.co.jp' then 
      domain1 = 'ray.co.jp' 
      ext = ''
    else
      if (mail.index('@') == nil) then   
        ext = '@' + domain 
        domain1 = domain
      else 
        domain = ""
        ext = ''
      end 
    end 
    dn = "uid=#{mail}#{ext},ou=Mail,dc=ray,dc=co,dc=jp"
    attr = {
      :objectClass =>  "mailUser" ,
      :cn => sei+mei,
      :sn => sei, 
      :uid => mail + ext, 
      :givenName => f_name + "　" + name , 
      :employeeNumber => shain, 
      :userPassword => passwd,  
      :homeDirectory => "/data/home/vmail/#{domain}/#{mail}" ,
      :mailDir => "#{domain}/#{mail}/Maildir/",
      :mail => "#{mail}@#{domain1}" ,
      :mailQuota => '256' , 
      :accountKind => actkind ,
      :mailForward => traddr, 
      :wifiuid => mail ,
      :accountActive => "TRUE",
      :domainName => domain,  
      :transport => 'virtual'
    }
    ## print ldif 
    ## accountKind : personal:1,transfer:2,alias:3,grouptr:4,ML:5,admin:6,other:7 
    ldif  = sprintf "dn: #{dn}\n"  
    ldif += sprintf "objectClass: mailUser\n"
    ldif += sprintf "cn: #{sei}#{mei}\n"
    ldif += sprintf "sn: #{sei}\n" 
    ldif += sprintf "uid: #{mail}#{ext}\n" 
    ldif += sprintf "employeeNumber: #{shain}\n" 
    ldif += sprintf "userPassword: #{passwd}\n"   
    ldif += sprintf "homeDirectory: /data/home/vmail/#{domain}/#{mail}\n"
    ldif += sprintf "mailDir: #{domain}/#{mail}/Maildir/\n"
    ldif += sprintf "mail: #{mail}@#{domain1}\n"
    ldif += sprintf "mailQuota: 256\n" 
    ldif += sprintf "accountKind: #{actkind}\n"
    ldif += sprintf "mailForward: #{traddr}\n" if actkind != "1" 
    ldif += sprintf "wifiuid: #{mail}\n"
    ldif += sprintf "accountActive: TRUE\n"
    ldif += sprintf "domainName: #{domain}\n"   
    ldif += sprintf "transport: virtual\n"
    File.write( "./ldifbackup/" +mail+ext,ldif) 
## print dnet csv
##    dnet = sprintf ("0,0,")
##    dnet += sprintf("#{sei}　#{mei},#{f_name}　#{name},#{shain},#{passwd},#{mail}@#{domain},,,,,,,,,,,,,,,,,,d00001,rg1099" )

##    File.write( "./dnetbackup/" +mail+".csv",dnet) 
    if wrok then 
      Net::LDAP.open(:host =>'ldap.ray.co.jp',:port => 389 , :auth => auth  ) do |ldap|
        #  ,:encryption => :simple_tls # ldap.port = 389 636
      #    p filter
        p dn if $DEBUG 
        p attr if $DEBUG
        ldap.add( :dn => dn, :attributes => attr ) 
        p ldap.get_operation_result  if $DEBUG #  .code 
        result = ldap.get_operation_result.to_s  #  .code 
        log.info("added #{dn}" )
      end 
    end
  end 
end

def ldapvalue(attr, val, ndattr, ldap ) ## ou= Mail
  log = Logger.new('/var/log/ldap.log')
  log.level = Logger::WARN
  puts "ldapvalue: #{ldap} #{attr} #{val}" 
  if ldap == "ldap.ray.co.jp" then 
    auth = { :method => :simple, :username => "cn=Manager,dc=ray,dc=co,dc=jp", :password => "ray00" }
    treebase = "ou=Mail,dc=ray,dc=co,dc=jp"
  else 
    auth = { :method => :simple, :username => "cn=Manager,dc=ray,dc=jp", :password => "1234" }
    treebase = "ou=Mail,dc=ray,dc=jp"
  end 
  p auth 
  hits =0
  result = "not executed" 
#  begin
    Net::LDAP.open(:host => ldap, :port => 389 , :auth => auth  ) do |ldap|
    #  ,:encryption => :simple_tls # ldap.port = 389 636
      filter = Net::LDAP::Filter.eq( attr, val)
#    p filter
      ldap.search(:base => treebase, :filter => filter ) do |entry|
        puts "search result:#{entry}" 
        hits+= 1
        if ndattr == "DN" then
##          log.warn("ldapvalue: #{ndattr}:DN: #{entry.dn}" )
          return entry.dn
        end
##        log.warn("ldapvalue: DN: #{entry.dn} #{entry[ndattr][0]}")
        return entry[ndattr][0]
      end
##      log.info(ldap.get_operation_result)
    end
    if hits == 0 then 
      return true 
    else 
      return false
    end
#  rescue => ex
#    log.fatal( ex)
#    return true 
#  end
end 
def hasattr(uid,attr, ldap)
  log = Logger.new('/var/log/ldap.log')
  log.level = Logger::WARN
  if ldap == "ldap.ray.co.jp" then 
    auth = { :method => :simple, :username => "cn=Manager,dc=ray,dc=co,dc=jp", :password => "ray00" }
    treebase = "ou=Mail,dc=ray,dc=co,dc=jp"
  else 
    auth = { :method => :simple, :username => "cn=Manager,dc=ray,dc=jp", :password => "1234" }
    treebase = "ou=Mail,dc=ray,dc=co,dc=jp"
  end
  hits =0
  result = "not executed" 
  begin
    Net::LDAP.open(:host => ldap,:port => 389 , :auth => auth  ) do |ldap|
    #  ,:encryption => :simple_tls # ldap.port = 389 636
      filter = Net::LDAP::Filter.eq( 'uid', uid)
#    p filter
      ldap.search(:base => treebase, :filter => filter ) do |entry|
      puts entry
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

def getpass(email)
  ldap = getldap(email)
  if  ldap == true then 
    return true 
  else 
    return ldapvalue( 'mail', email , 'userPassword', ldap)
  end 
end

def getname(email )
  if (ldap = getldap(email)) == true then 
    return true 
  else 
    return ldapvalue( 'mail', email , 'cn', ldap)
  end 
end

def getgname(email )
  if (ldap = getldap(email)) == true then 
    return true 
  else 
    return ldapvalue( 'mail', email , 'givenName',getldap(email))
  end 
end
#-
# ldifからemailを取り出して返す.
#++
def emcheck(email)
  log = Logger.new('/var/log/ldap.log')
  log.level = Logger::WARN
  if email.index("@") == nil then
    log.warn("error: no @ in #{email}") 
    return true
  end
  bb = email.split('@')
  if $tdomain.index(bb[1]) == nil then
    ## not supported
    ## log.warn("domain #{bb[1]} not supported." )
    return nil
  else
    id = bb[0]
    domain = bb[1]
  end
  return ldapvalue('mail', email, 'mail', $ldap)
end

#-
# 転送アドレスを取得
#++
def getfwd(addr, ldap)
  log = Logger.new('/var/log/ldap.log')
  log.level = Logger::INFO
  if ldap == "wm2.ray.co.jp" then 
    auth = { :method => :simple, :username => "cn=Manager,dc=ray,dc=jp", :password => "1234" }
    treebase = "ou=Mail,dc=ray,dc=jp"
  else 
    auth = { :method => :simple, :username => "cn=Manager,dc=ray,dc=co,dc=jp", :password => "ray00" }
    treebase = "ou=Mail,dc=ray,dc=co,dc=jp"
  end 
  hits =0
  result = "not executed"
  if (addr == nil) ||( addr.length < 1) then
    # アドレスが設定されていない
    return true 
  end 
#  begin
    Net::LDAP.open(:host => ldap, :port => 389 , :auth => auth  ) do |ldap|
      filter = Net::LDAP::Filter.eq('mail', addr)
      ldap.search(:base => treebase, :filter => filter ) do |entry|
        if ldap == "ldap.ray.co.jp" then 
          knd = entry['accountKind'][0] 
          if ((knd == '2') || (knd =='1')) then  ## make sure this is forward address 
            STDERR.puts entry
            hits+= 1
            log.info("mailForward: DN: #{entry.dn} #{entry['mailForward'][0]}")
            return entry['mailForward'] 
          else 
            STDERR.puts("accountKind = #{entry['accountKind']}") 
            return true 
          end
        else
          return entry['mailForward'] 
        end 
      end
      return true
    end
#  rescue => ex
    log.fatal( ex)
    return true
  end 
#end
#-
# DN エントリーのすべてのデータを返す
#++ 
def ldapdisplay(treebase, id, value)
  if (treebase== nil) || (id == nil) || (value== nil)then 
    puts "Bad parameters," if $DEBUG
    return nil
  end 
  if (treebase.length< 1) || (id.length< 1 ) || (value.length <1)then 
    puts "Bad parameters," if $DEBUG
    return nil
  end 
  auth = { :method => :simple, :username => "cn=Manager,dc=ray,dc=co,dc=jp", :password => 'ray00' }
  filter = Net::LDAP::Filter.eq(id ,value) 
  result = Array.new 
  num = 0
  begin 
    Net::LDAP.open(:host=> 'ldap.ray.co.jp',:port=>389, :auth =>auth) do |ldap|
      ldap.search(:base => treebase, :filter => filter) do |entry|
        result.push(id+value) 
        num += 1
        entry.each do |attribute,values|
          result.push( "#{attribute}:")
          values.each do |value|
            result.push("   -->#{value}") 
          end
        end
      end
    end
  rescue => ex
    result.push(ex)
    return nil  
  end  
  if num == 0 then 
    return nil 
  else 
    return result 
  end
end 


#-
# dn エントリーを削除
#++ 
def ldapdel(dn)
  log = Logger.new('/var/log/ldap.log')
  log.level = Logger::INFO
  oplog = Logger.new('/var/log/ldapop.log')
  oplog.level = Logger::INFO
  auth = { :method => :simple, :username => "cn=Manager,dc=ray,dc=co,dc=jp", :password => "ray00" }
  hits =0
  result = "not executed"
  puts "dn = #{dn}" if $DEBUG 
  begin
    Net::LDAP.open(:host =>'ldap.ray.co.jp',:port => 389 , :auth => auth  ) do |ldap|
      result = ldap.delete :dn => dn 
      puts result 
      puts ldap.get_operation_result
      oplog.info("#{dn} deleted,") 
      return result 
    end
  rescue => ex
    log.fatal( ex)
    return true
  end 
end

def addattr(uid, attr, value) 
  log = Logger.new('/var/log/ldap.log')
  log.level = Logger::WARN
  oplog = Logger.new('/var/log/ldapop.log')
  oplog.level = Logger::INFO
  auth = { :method => :simple, :username => "cn=Manager,dc=ray,dc=co,dc=jp", :password => "ray00" }
  hits =0
  result = "not executed"
  Net::LDAP.open(:host =>'ldap.ray.co.jp',:port => 389 , :auth => auth  ) do |ldap|
  #  ,:encryption => :simple_tls # ldap.port = 389 636
    filter = Net::LDAP::Filter.eq('uid', uid)
#  p filter
    treebase = "ou=Mail,dc=ray,dc=co,dc=jp"
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
def vstr?( str)
  if str == nil then 
    return false
  elsif str.length == 0 then  
    return false
  end 
  return true
end 

def fwedit(fwaddr, modaddr, cmd)
  log = Logger.new('/var/log/ldap.log')
  log.level = Logger::WARN
  oplog = Logger.new('/var/log/ldapop.log')
  oplog.level = Logger::INFO
  unless vstr?(cmd) then 
    STDERR.puts "Error: fwedit: cmd not defined."
    return nil
  end
  unless vstr?(fwaddr) then
    STDERR.purs "Error: fwedit: fwaddr not defined."
    return nil
  end 
  unless vstr?(modaddr) then
    STDERR.puts "Error: fwedit: modaddr not defined."
    return nil
  end 
  auth = { :method => :simple, :username => "cn=Manager,dc=ray,dc=co,dc=jp", :password => "ray00" }
  hits =0
  result = "not executed" 
  p cmd
  case cmd
  when 'chk','add','del'
    p cmd if $deb 
#    begin
      Net::LDAP.open(:host =>'ldap.ray.co.jp',:port => 389 , :auth => auth  ) do |ldap|
      #  ,:encryption => :simple_tls # ldap.port = 389 636
        filter = Net::LDAP::Filter.eq('mail', fwaddr)
  #    p filter
        treebase = "ou=Mail,dc=ray,dc=co,dc=jp"
        $resdn = nil
        ldap.search(:base => treebase, :filter => filter ) do |entry|
  #        if entry.length > 1 then 
  #          log.warn("fwedit: entry size =#{entry.size}")
  #        end 
  #      puts entry
          $resdn = entry.dn
          $valx = entry['mailForward'][0]
          puts $valx
        end
        if $resdn == nil then 
          puts "cannot find entry dn"
          return true 
        end
#        log.warn("mailForward: #{cmd} DN: #{$resdn}")
#        p "$valx=#{$valx}"  
        if ($valx == nil ) then
          $valw = Array.new 
        else 
          $valw = $valx.split(',')
        end 
#        p "$valw=#{$valw}"  
        if (cmd == 'add') then
          if $valw.index(modaddr) == nil then 
            $valw.push(modaddr)
            $valw.uniq!
          else 
            STDERR.puts "#{modaddr} is already included in transfer address <#{fwaddr}>. No operation done."
            return true  
          end  
        elsif cmd == 'del' then 
          $valw.delete(modaddr) 
        elsif cmd == 'chk' then
          puts "checking..."  
          result = $valw.index(modaddr)
          if result == nil then
            STDERR.puts "#{modaddr} is not included in transfer address <#{fwaddr}>"
          else 
            STDERR.puts "#{modaddr} is included in transfer address <#{fwaddr}>"
          end
          puts "#{$valw.size} address in the list." 
          return result 
        else 
          log.fatal("fwedit: cmd error = #{cmd}")
          return true 
        end
        $valx = $valw.join(',')
        puts $resdn 
        result = ldap.replace_attribute $resdn, :mailForward, $valx 
        ##result = ldap.modify :dn => $resdn, :operations => ops 
        p result 
        res1 = ldap.get_operation_result 
        p res1 
        puts "operation result: #{res1}" 
        oplog.info("ldap modify mailForward:#{fwaddr} #{cmd},#{modaddr} -#{$resdn}:#{res1}" )
        puts "#{$valw.size} address in the list." 
        return result
      end
      puts "failed to open ldap"
      return true 
#    rescue => ex
      log.fatal( ex)
      p ex 
      return true 
#    end
  else 
    STDERR.puts "fwdedit: cmd error: cmd=#{cmd}" 
    return true
  end 
end 
  
def kanayomi(pass)
  trns =  [ "えー", "びー",  "しー", "でぃー", "いー","えふ",  "じー", "えいち",  "あい","じぇい",  "けい",  "える","えむ","えぬ","おー","ぴー","きゅー", "あーる", "えす","てぃー" ,"ゆー","ぶい", "だぶりゅー","えっくす","わい","ぜっと","みぎかっこ","えんまーく","ひだりかっこ","やまがた","あんだーばー","いんよう","えー", "びー",  "しー", "でぃー", "いー","えふ",  "じー", "えいち",  "あい","じぇい",  "けい",  "える","えむ","えぬ","おー","ぴー","きゅー", "あーる", "えす","てぃー" ,"ゆー","ぶい", "だぶりゅー","えっくす","わい","ぜっと","みぎだいかっこ","たてぼう","ひだりだいかっこ","てん","さくじょ" ]
  ##  !"#$%&'()*+,-./=> 32..47
  kigou1 = [ "スペース","エクスクラメーション","にじゅういんよう","いげた","どる","ぱーせんと","あんど","いんよう","みぎかっこ","ひだりかっこ","アスタリスク", "プラス","カンマ","マイナス","ピリオド","スラッシュ" ]
  # :;<=>?@  58-64  
  kigou2 = [ "コロン","セミコロン","小なり","イコール","大なり","クエスチョン","アトマーク" ]
  numa = [ "ぜろ","いち","に","さん","よん","ご","ろく","なな","はち","きゅー","ころん","せみころん","しょうなり","いこーる","だいなり","くえすちょん","あとまーく","","", ]
  res = ""
  i = 0
  if pass == nil then 
    return "Error in ldaputil/kanayomi pass==nil " 
  end
  pass.each_byte do |c|
    if i > 0 then ## separator  
      res += "・" 
    end
    case c
    when 32..47   ## kigou 
      res += kigou1[c-32]   
    when 48..57   ## numbers 
      res += numa[c- 48]
    when 58..64 ## kigou2
      res += kigou2[c-58]
    when 65..127  ## alphabet 
      res += trns[c -65]
    else 
      res += "コードエラー"    ## no reading... return itself... 
    end 
      i += 1 
  end
  return res
end 

def dhms(sec)
  d = sec / (60 * 60 * 24)
  t = sec - (d * 60 * 60 * 24)
  h = t / (60 * 60)
  t -= h * (60 * 60)
  m = t / 60
  s = t - ( m * 60 )
  return sprintf("%02d:%02d:%02d:%02d", d,h,m,s)
end

def valid_email_address?(str)
	ans = false
        if str =~ /[\*\\\?]/ then 
          return false
        end 
	ans = true if str =~ /^[a-zA-Z0-9_\#!$%&`'*+\-{|}~^\/=?\.]+@[a-zA-Z0-9_\#!$%&`'*+\-{|}~^\/=?\.]+$/
	return ans
end  
#a ='0rawekaZA0123'
#puts a 
#puts kanayomi (a)
