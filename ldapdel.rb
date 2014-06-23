#!/usr/local/bin/ruby

require 'net/ldap'
require 'cgi'
require './ldaputil.rb'
require 'optparse'
require 'logger' 

puts "deleting address.."
puts "address to delete" 

## main start
opt = OptionParser.new
OPTS = {}
Version = '0.1' 
$deb = false 
$ml = false 

opt.on('-d', 'debug mode ') { $deb = true }
opt.on('-m', 'mailing list mode ') { $ml = true }

puts ARGV[0] ,ARGV[1], ARGV[2]
rr = opt.parse!(ARGV)
puts "$deb=#{$deb}, $ml=#{$ml}" 

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
case wid[1] #  domain part 
when 'ray.co.jp'
    if ( $ml == true) then 
      ldapdel("uid=#{email},ou=Mail,dc=ray,dc=co,dc=jp", ldap)
    else 
      ldapdel("uid=#{uid},ou=Mail,dc=ray,dc=co,dc=jp", ldap)
    end 
when 'ss.ray.co.jp' 
    ldapdel("uid=#{email},ou=Mail,dc=ray,dc=co,dc=jp", ldap)
else
  case ldap
  when 'ldap.ray.co.jp'
    ldapdel("uid=#{email},ou=Mail,dc=ray,dc=co,dc=jp", ldap)
  when 'wm2.ray.co.jp'
    ldapdel("uid=#{email},ou=Mail,dc=ray,dc=jp", ldap)
  else 
    STDERR.puts("ldap server error.")
  end 
end
