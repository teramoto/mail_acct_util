#!/usr/local/bin/ruby

require 'net/ldap'
require 'cgi'
require './ldaputil.rb'
require 'optparse'
require 'logger' 
require 'byebug' 

puts "enabling address.."
puts "address to change" 

## main start
opt = OptionParser.new
OPTS = {}
Version = '0.2' 
$deb = false 
$ml = false 
stat = false 
$val = false 
$pass = "" 
opt.on('-d', 'debug mode ') { $deb = true }
opt.on('-m', 'mailing list mode ') { $ml = true }
opt.on('-v true/false', 'AccountActive value') {|v|  $val = v } 
opt.on('-p new password', 'new Password') {|v| $pass = v } 
 
puts ARGV[0] ,ARGV[1], ARGV[2]
rr = opt.parse!(ARGV)
puts rr 
puts "$deb=#{$deb}, $ml=#{$ml}" 
puts "value #{$val}:#{$val.class}" 
byebug if $deb 

#puts getfwd ARGV[0]
wid = ARGV[0].split('@')
if wid == nil then 
  STDERR.puts "Invalid email address."
  exit(-1)
end
if wid[0] == nil then 
  STDERR.puts "local not exist.#{ARGV[0]}"
  exit(-1)
end
if wid[1] == nil then 
  STDERR.puts "domain not exist.#{ARGV[0]}" 
  exit(-1)
end

email = ARGV[0] 
uid = wid[0]  
domain = wid[1]
ldap = getldap(email)
puts "uid=#{uid}, email=#{email}" 
$deb = true 
byebug 
case wid[1] #  domain part 
when 'ray.co.jp'
    if ( $ml == true) then 
      ldapenable("uid=#{email},ou=Mail,dc=ray,dc=co,dc=jp", ldap, $val)
    else
      ldaprplattr("uid=#{uid},ou=Mail,dc=ray,dc=co,dc=jp", uid, 'userPassword', $pass , ldap )
    end 
when 'ss.ray.co.jp','mcray.jp'  
  #   ldapenable("uid=#{email},ou=Mail,dc=ray,dc=jp", ldap, $val)
      ldaprplattr("uid=#{email},ou=Mail,dc=ray,dc=jp", email, 'userPassword', $pass , ldap )
else
  case ldap
  when 'ldap.ray.co.jp'
  #  ldapenable("uid=#{email},ou=Mail,dc=ray,dc=co,dc=jp", ldap, $val)
  when 'ldap2.ray.co.jpi'
  when 'ldap23.ray.co.jp' 
   #  ldapenable("uid=#{email},ou=Mail,dc=ray,dc=jp", ldap, $val)
     ldaprplattr("uid=#{email},ou=Mail,dc=ray,dc=jp", email, 'userPassword', $pass , ldap )
  else 
    STDERR.puts("ldap server error.")
  end 
end
