#!/usr/local/bin/ruby

require 'net/ldap'
require 'cgi'
require './ldaputil1.rb'

puts ARGV[0] 
puts getname(ARGV[0])
puts getgname(ARGV[0])
exit 0

bb = ARGV[0].split('@')
if $tdomain.index(bb[1]) then 
  ldap = 'ldap.ray.co.jp' 
elsif $udomain.index(bb[1]) then 
  ldap = 'wm2.ray.co.jp' 
end 
if bb[1] == 'ray.co.jp' then 
  uid = bb[0]
else 
  uid = ARGV[0]
end 
res = ldapvalue( "mail" , mail, 'userPassword', ldap )
p res
puts res
puts res == true
puts res == false
res = getname(ARGV[0])
p res 
res = getpass(ARGV[0]) 
p res  
