#!/usr/local/bin/ruby
# encoding : utf-8 

require 'net/ldap'
require 'logger'
require 'tracer' 
require 'romaji'
#
# debug mode is controlled via $deb 
#

#
# Decide path for log file.
# 
GLOGPATH = '/var/log'
LLOGPATH = 'log'
LOGFILE = 'ldap.log' 
def logpathset
  if $logpath == nil then 
    begin 
      fp = File.open('/var/log/ldap.log','a+')
    rescue 
      $logpath = nil
    else 
      $logpath = '/var/log/ldap.log'
    end 
    if $logpath == nil then 
      begin 
        fp = File.open('log/ldap.log','a+')
        $logpath = 'log/ldap.log'
      rescue => ex
        STDERR.puts  ex  
        STDERR.puts "can't open log file"
        begin 
          if File::ftype('log') == 'directory' then 
            $logpath= 'log/ldap.log'
          end
        rescue => ex1 
          STDERR.puts ex1
          begin 
            Dir::mkdir('log') 
            $logpath = 'log/ldap.log'
          rescue => ex2  
            STDERR.puts ex2 
            $logpath = nil
          end 
        end  
        retry   
      else 
        if fp != nil then 
          $logpath= 'log/ldap.log'
        end
      end
    end
  end 
  if $logpathop == nil then 
    begin 
      fp = File.open('/var/log/ldapop.log','a+')
    rescue
      $logpathop = nil
    else
      $logpathop = '/var/log/ldapop.log'
    end
    if $logpathop == nil then
      begin 
        fp = File.open('log/ldapop.log','a+')
      rescue => ex 
        STDERR.puts ex 
        STDERR.puts"can't open operation log file"
        $logpathop == nil
      else 
        if fp != nil then 
          $logpathop= 'log/ldapop.log'
        end  
      end
    end 
  end 
end
 
def logopen 
  logpathset 
  if $logpath then 
    log = Logger.new($logpath)
    log.level = Logger::WARN
  end
  return log 
end 

def logopenop
  logpathset
  if $logpathop then 
    log = Logger.new($logpathop)
    log.level = Logger::WARN 
  end 
  return log
end 

#
# global arrays for domains handled 
# 
#  handled by smtp.ray.co.jp
$tdomain = [ "plays.co.jp", "digisite.co.jp", "wbc-dvd.com", "tera.nu", "tc-max.co.jp"  ]
# handled by sakura server www16276uf.sakura.ne.jp
$udomain = [ "ss.ray.co.jp" , "nissayseminar.jp", "nissayspeech.jp", "mcray.jp", "lic.prent.jp" ]
$vdomain = [ "wes.co.jp" ]  # web areana 
$wdomain = [ "tc-max.co.jp" ] 
$cdomain = [ "ray.co.jp" , "digisite.co.jp", "plays.co.jp" ]
#
# get ldap host from email  
#
def getldap( email )  
  if email == nil then 
    return true 
  end 
  ld = email.split('@')
  if ld == nil then 
    STDERR.puts "invalid email #{email}" 
    return true 
  end 
  if $tdomain.index(ld[1]) then
    return  'ldap.ray.co.jp'
  elsif $udomain.index(ld[1]) then
    return  'wm2.ray.co.jp'
  else 
    return nil  # no ldap server to use...
  end 
end

#
# output ldap 
# mode = 1 : create, 2 : reset 
#
def ldapout(uid, mail, passwd, sei, mei, domain, f_name, name, shain , actkind, traddr)

  wrok = true  # control output to ldif database 
  mode = 1 
  if (mail.index('@') != nil)  then 
    STDERR.puts ("mail should not be with domain.(#{mail})" )
    exit (-1)
  end
  if $logpath then 
    log = Logger.new($logpath)
    log.level = Logger::WARN
  end 
  if (passwd == nil) || (passwd.length < 6) then 
    passwd = mkps8  
    puts "password:#{passwd}" if $deb
    log.warn(passwd) if $logpath 
  end 
  ## check email address exists on ldap db.....
  attr = "mail"
  target = mail + "@" + domain

  puts target if $deb
  if $tdomain.index(domain) != nil && mode !=2  then 
    auth = { :method => :simple, :username => "cn=Manager,dc=ray,dc=co,dc=jp", :password => "ray00" }
    hits=0
    if domain == "tc-max.co.jp" then 
      STDERR.puts ("Warning! #{domain} support is under development.")
    end 
    result = "not executed" 
    begin
      Net::LDAP.open(:host =>'ldap.ray.co.jp',:port => 389 , :auth => auth  ) do |ldap|
      #  ,:encryption => :simple_tls # ldap.port = 389 636
        filter = Net::LDAP::Filter.eq( attr, target)
        p filter if $deb 
        treebase = "ou=Mail,dc=ray,dc=co,dc=jp"
        ldap.search(:base => treebase, :filter => filter ) do |entry|
          puts entry if $deb
          uidc = 0
          hits+= 1
          log.warn("DN: #{entry.dn}") if $logpath 
          entry.each do |attribute, values|
            if attribute == 'uid' then
              uidc += 1
              puts "<#{attribute}>" if $deb
            end
            print " #{attribute}:" if $deb
            values.each do |value|
              print "#{value}" if $deb
            end
            print "\n" if $deb 
          end
          if uidc > 1 then
            log.warn( "uid#{uidc}  error in #{entry.dn}") if $logpath 
            puts ( "uid#{uidc}  error in #{entry.dn}") if $deb 
          end
        end
      log.info(ldap.get_operation_result) if $logpath 
      end
    rescue => ex
      log.FATAL( ex) if $logpath 
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
        p dn if $deb 
        p attr if $deb
        ldap.add( :dn => dn, :attributes => attr ) 
        p ldap.get_operation_result  if $deb #  .code 
        result = ldap.get_operation_result.to_s  #  .code 
        log.info("added #{dn}" ) if $logpath 
      end 
    end
  end 
end

#
# return value for specific attribute. 
#
def ldapvalue(attr, val, ndattr, ldap ) ## ou= Mail
  logopen 
  if ldap == "ldap.ray.co.jp" then 
    auth = { :method => :simple, :username => "cn=Manager,dc=ray,dc=co,dc=jp", :password => "ray00" }
    treebase = "ou=Mail,dc=ray,dc=co,dc=jp"
  else 
    auth = { :method => :simple, :username => "cn=Manager,dc=ray,dc=jp", :password => "1234" }
    treebase = "ou=Mail,dc=ray,dc=jp"
  end 
  hits =0
  result = "not executed" 
#  begin
    Net::LDAP.open(:host => ldap, :port => 389 , :auth => auth  ) do |ldap|
    #  ,:encryption => :simple_tls # ldap.port = 389 636
      filter = Net::LDAP::Filter.eq( attr, val)
#    p filter
      ldap.search(:base => treebase, :filter => filter ) do |entry|
        hits+= 1
        if ndattr == "DN" then
##          log.warn("ldapvalue: #{ndattr}:DN: #{entry.dn}" ) if $logpath 
          return entry.dn
        end
##        log.warn("ldapvalue: DN: #{entry.dn} #{entry[ndattr][0]}") if $logpath 
        return entry[ndattr][0]
      end
##      log.info(ldap.get_operation_result) if $logpath 
    end
    if hits == 0 then 
      return true 
    else 
      return false
    end
#  rescue => ex
#    log.fatal( ex) if $logpath 
#    return true 
#  end
end

#
# Check if ldap record has attribute.
# 
def hasattr(uid,attr, ldap)
  if $logpath then 
    log = Logger.new($logpath)
    log.level = Logger::WARN
  end 
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
      puts entry if $deb
        hits+= 1
        return entry[attr][0]
      end
##      log.info(ldap.get_operation_result) if $logpath 
    end
  rescue => ex
    log.fatal( ex) if $logpath 
    return true 
  end
end
#
# get password from ldap 
#
def getpass(email)
  ldap = getldap(email)
  if  ldap == true then 
    return true 
  else 
    return ldapvalue( 'mail', email , 'userPassword', ldap)
  end 
end
#
# get name record of specific e-mail address 
#
def getname(email )
  if (ldap = getldap(email)) == true then 
    return true 
  else 
    return ldapvalue( 'mail', email , 'cn', ldap)
  end 
end
#
# get given name for specific email address 
#
def getgname(email )
  if (ldap = getldap(email)) == true then 
    return true 
  else 
    return ldapvalue( 'mail', email , 'givenName',getldap(email))
  end 
end
#
# ldifからemailを取り出して返す.
#
def emcheck(email)
  if $logpath then
    log = Logger.new($logpath)
    log.level = Logger::WARN
  end 
  if email.index("@") == nil then
    log.warn("error: no @ in #{email}") if $logpath 
    return true
  end
  bb = email.split('@')
  if $tdomain.index(bb[1]) == nil then
    ## not supported
    ## log.warn("domain #{bb[1]} not supported." ) if $logpath 
    return nil
  else
    id = bb[0]
    domain = bb[1]
  end
  return ldapvalue('mail', email, 'mail', $ldap)
end

#
# 転送アドレスを取得
#
def getfwd(addr, ldap)
  if $logpath then 
    log = Logger.new($logpath)
    log.level = Logger::INFO
  end 
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
            log.info("mailForward: DN: #{entry.dn} #{entry['mailForward'][0]}") if $debug
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
    log.fatal( ex) if $logpath 
    return true
  end 
#end
#
# DN エントリーのすべてのデータを表示する。
# 
def ldapdisplay(treebase, id, value)
  if (treebase== nil) || (id == nil) || (value== nil)then 
    puts "Bad parameters," if $deb
    return nil
  end 
  if (treebase.length< 1) || (id.length< 1 ) || (value.length <1)then 
    puts "Bad parameters," if $deb
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


#
# dn エントリーを削除
# 
def ldapdel(dn,host)
  if $logpath then 
    log = Logger.new($logpath)
    log.level = Logger::INFO
  end
  if $logpathop != nil then 
    oplog = Logger.new($logpathop)
    oplog.level = Logger::INFO
  end
  if host == 'ldap.ray.co.jp' then  
    auth = { :method => :simple, :username => "cn=Manager,dc=ray,dc=co,dc=jp", :password => "ray00" }
  else 
    auth = { :method => :simple, :username => "cn=Manager,dc=ray,dc=jp", :password => "1234" }
  end 
  hits =0
  result = "not executed"
  puts "dn = #{dn}" if $deb 
  begin
    Net::LDAP.open(:host => host ,:port => 389 , :auth => auth  ) do |ldap|
      result = ldap.delete :dn => dn 
      puts result 
      puts ldap.get_operation_result
      oplog.info("#{dn} deleted,") if $logpathop  
      return result 
    end
  rescue => ex
    log.fatal( ex) if $logpath 
    return true
  end 
end

#
# Replace attribute of ldap record.... 
# 
def ldaprplattr(dn, uid, attr, value, ldaphost ) 

  log = logopen
  oplog = logopenop
  case ldaphost
  when 'ldap.ray.co.jp' 
    auth = { :method => :simple, :username => "cn=Manager,dc=ray,dc=co,dc=jp", :password => "ray00" }
    treebase = "ou=Mail,dc=ray,dc=co,dc=jp"
  when 'wm2.ray.co.jp'
    auth = { :method => :simple, :username => "cn=Manager,dc=ray,dc=jp", :password => "1234" }
    treebase = "ou=Mail,dc=ray,dc=jp"
  end 
  hits =0
  result = "not executed"
  STDERR.puts dn if $deb 
  Net::LDAP.open(:host => ldaphost, :port => 389 , :auth => auth  ) do |ldap|
    STDERR.puts("ldap opend sucessfully") if $deb 

  #  ,:encryption => :simple_tls # ldap.port = 389 636
    filter = Net::LDAP::Filter.eq('uid', uid)
#  p filter
    $resdn = ""
    ldap.search(:base => treebase, :filter => filter  ) do |entry|
      p entry 
#      STDERR.puts("entry found sucessfully") if $deb 
#      if entry.size > 1 then
#        log.warn("ldaprplattr: entry size =#{entry.size}") if $logpath 
#        STDERR.puts("ldaprplattr: entry size =#{entry.size}") if $deb 
#      end
      $resdn = entry.dn
    end
    p $resdn 
    puts $resdn 
    puts "#{attr} => #{value}" 
    result = ldap.replace_attribute($resdn, attr, value)
    return result 
  end
  oplog.warn("ldaprplattr :DN: #{$resdn}: #{attr} : #{value} ") if $logpathop
end

#
# Add attribute.... 
# 
def addattr(uid, attr, value) 
  if $logpath then 
    log = Logger.new($logpath)
    log.level = Logger::WARN
  end 
  if $logpathop then   
    oplog = Logger.new($logpathop)
    oplog.level = Logger::INFO
  end 
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
#        log.warn("fwedit: entry size =#{entry.size}") if $logpath 
#      end
#    puts entry
      $resdn = entry.dn
    end

    result = ldap.add_attribute($resdn, attr, value)
    return result 
  end
  oplog.warn("addattr :DN: #{$resdn}: #{attr} : #{value} ") if $logpathop
end
#
#  check string is valid (not nil and length > -)
#
def vstr?( str)
  if str == nil then 
    return false
  elsif str.length == 0 then  
    return false
  end 
  return true
end 
#
# edit forwading address.. ( add, del members. )
# 
def fwedit(fwaddr, modaddr, cmd)
  if $logpath then 
    log = Logger.new($logpath)
    log.level = Logger::WARN
  end 
  if $logpathop then 
    oplog = Logger.new($logpathop)
    oplog.level = Logger::INFO
  end 
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
  #          log.warn("fwedit: entry size =#{entry.size}") if $logpath 
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
#        log.warn("mailForward: #{cmd} DN: #{$resdn}") if $logpath 
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
          log.fatal("fwedit: cmd error = #{cmd}") if $logpath 
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
        oplog.info("ldap modify mailForward:#{fwaddr} #{cmd},#{modaddr} -#{$resdn}:#{res1}" ) if $logpathop
        puts "#{$valw.size} address in the list." 
        return result
      end
      puts "failed to open ldap"
      return true 
#    rescue => ex
      log.fatal( ex) if $logpath 
      p ex 
      return true 
#    end
  else 
    STDERR.puts "fwdedit: cmd error: cmd=#{cmd}" 
    return true
  end 
end 
#
# return Japanese reading of ascii letters...
#  
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

#
# convert second to day, hour,min,sec string 
#
def dhms(sec)
  d = sec / (60 * 60 * 24)
  t = sec - (d * 60 * 60 * 24)
  h = t / (60 * 60)
  t -= h * (60 * 60)
  m = t / 60
  s = t - ( m * 60 )
  return sprintf("%02d:%02d:%02d:%02d", d,h,m,s)
end

#
# Check the string is valid email address
#
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
