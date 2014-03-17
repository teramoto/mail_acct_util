#!/usr/local/bin/ruby -W0
# encoding : utf-8 

require 'net/ldap'
require 'cgi'
require 'logger'
require './passwdgen.rb' 

# check and create 

def exit_job
  
  if $mail && ($mail.index('@') == nil) then 
    $mail += '@' + $domain 
  end 
  redirect_url = 'mchk.rhtml' + '?' + "result=#{$result}&email=#{$mail}&domain=#{$domain}&shain=#{$shain}&passwd=#{$passwd}&mei=#{$mei}&sei=#{$sei}&name=#{$name}&f_name=#{$f_name}" 

  ## $log.warn( cgi.header({ 'status' => 'REDIRECT', 'Location' => redirect_url} ))
  print $cgi.header({ 'status' => 'REDIRECT', 'Location' => redirect_url} )
  
end 

def exit_finish
  cgi.out() do
    cgi.html() do
      cgi.head{ cgi.title{"メールアドレス作成完了"} } +
      cgi.body() do
        cgi.form() do
          cgi.textarea("get_text") +
          cgi.br +
          cgi.submit
        end +
        cgi.pre() do
          CGI.escapeHTML(
            "params: " + cgi.params.inspect + "\n" +
            "cookies: " + cgi.cookies.inspect + "\n" +
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
$tdomains = [ "ray.co.jp", "plays.co.jp", "digisite.co.jp","tc-max.co.jp","wes.co.jp"  ] 
$log = Logger.new('/var/log/ldap.log')
$log.level = Logger::WARN
$cgi = CGI.new()
# $cgi = CGI.new("html5")
if $cgi['debug'] ==""  then 
  $DEBUG = false
else 
  $DEBUG = $cgi['debug']
end 
#$stderr_sv = STDERR.dup
#STDERR.reopen("/var/log/ruby/error.log")
exit_finish 

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
end
$err = 0
if (($domain =="") || ($domain == 'ray.co.jp')) then
  if mad = $mail.split('@') then 
    $mail = mad[0]
    $domain = mad[1]
  end
end 
if $mail == nil || $mail =="" then 
  $result = "メールアドレスを指定してください．\n"
  $err +=1 
end 
if $domain==nil || $domain =="" then 
  $result = "ドメインを指定してください．"
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
$attr = "mail"
$target = $mail + "@" + $domain

puts $target if $DEBUG
if $tdomains.index($domain) != nil && $mode !=2  then 
  $auth = { :method => :simple, :username => "cn=Manager,dc=ray,dc=co,dc=jp", :password => "ray00" }
  $hits=0
  $result = "not executed" 
  begin
    Net::LDAP.open(:host =>'ldap.ray.co.jp',:port => 389 , :auth => $auth  ) do |ldap|
    #  ,:encryption => :simple_tls # ldap.port = 389 636
      filter = Net::LDAP::Filter.eq( $attr, $target)
      p filter if $DEBUG 
      treebase = "ou=Mail,dc=ray,dc=co,dc=jp"
      ldap.search(:base => treebase, :filter => filter ) do |entry|
        puts entry if $DEBUG
        uidc = 0
        $hits+= 1
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
    $log.FATAL( ex)
  end
  if $hits > 0 then
    $mailok = false 
    $result = "#{$target}_is_already_exists.#{$hits}"  
  else 
    $mailok = true 
    $result = "#{$target}_is_OK.#{$hits}"  
  end
else 
  $result = "ドメイン #{$domain}は未対応です。
  $mailok = false
end
