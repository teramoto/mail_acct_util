#!/usr/local/bin/ruby

require 'net/ldap'
require 'cgi'
require './ldaputil.rb'
require 'optparse'
require 'logger' 
require 'byebug' 

puts "enabling address.."
puts "address to change" 
puts "example ... ruby ldapenable -v false ken@ss.ray.co.jp"

## main start
opt = OptionParser.new
OPTS = {}
Version = '0.1' 
$deb = false 
$ml = false 
stat = false 
$val = false 

opt.on('-d', 'debug mode ') { $deb = true }
opt.on('-m', 'mailing list mode ') { $ml = true }
opt.on('-v true/false', 'AccountActive value') {|v|  $val = v } 
 
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
byebug if $deb 
case wid[1] #  domain part 
when 'ray.co.jp'
    if ( $ml == true) then 
      ldapenable("uid=#{email},ou=Mail,dc=ray,dc=co,dc=jp", ldap, $val)
    elseOB
 
      ldapenable("uid=#{uid},ou=Mail,dc=ray,dc=co,dc=jp", ldap, $val)
    end 
when 'ss.ray.co.jp' 
    ldapenable("uid=#{email},ou=Mail,dc=ray,dc=jp", ldap, $val)
else
  case ldap
  when 'ldap.ray.co.jp'
    ldapenable("uid=#{email},ou=Mail,dc=ray,dc=co,dc=jp", ldap, $val)
  when 'ldap2.ray.co.jp', 'ldap23.ray.co.jp' 
    ldapenable("uid=#{email},ou=Mail,dc=ray,dc=jp", ldap, $val)
  else 
    STDERR.puts("ldap server error.")
  end 
end
