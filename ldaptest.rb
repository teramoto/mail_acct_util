#!/usr/local/bin/ruby

require 'net/ldap'
require 'cgi'
require './ldaputil.rb'
require 'optparse' 

$deb = false

opt = OptionParser.new
opt.on('-d') {|v| $deb = true}

opt.parse!(ARGV)
p ARGV


puts ARGV[0] , ARGV[1] 
puts getname(ARGV[0])
puts getgname(ARGV[0])
# exit 0

bb = ARGV[0].split('@')
mail = ARGV[0] 
if $tdomain.index(bb[1]) then 
  ldap = 'ldap.ray.co.jp' 
elsif $udomain.index(bb[1]) then 
  ldap = 'ldap23.ray.co.jp' 
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
res = ldapvalue( "mail", mail, 'accountActive', ldap)
puts "accountActive = #{res}" 
p res.class
p res 
 dn = "uid=#{mail},ou=Mail,dc=ray,dc=jp"
 uid = mail 
 attr = 'accountActive' 
if ARGV[1] == nil then
  puts "finish!"
else
  byebug 
  if ARGV[1] == 'true' then
    value = 'TRUE'
  else 
    value = 'FALSE'
  end  
  res = ldaprplattr(dn, uid, attr, value, ldap )
  p res.class
  p res 
end
