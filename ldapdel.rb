#!/usr/local/bin/ruby

require 'net/ldap'
require 'cgi'
require './ldaputil.rb'
require 'optparse'
require 'logger' 

puts "deleting address.."
puts "address to del, cmd (add,del)" 

## main start
opt = OptionParser.new
OPTS = {}
Version = '0.1' 
deb = false 
opt.on('-d ', 'debug mode ') { deb = true }

puts ARGV[0] ,ARGV[1], ARGV[2]
rr = opt.parse!(ARGV)
#puts getfwd ARGV[0]
if ARGV[0].index('ss.ray.co.jp') != nil then 
  ldapdel("uid=#{ARGV[0]},ou=Mail,dc=ray,dc=jp", 'wm2.ray.co.jp')
else 
  ldapdel("uid=#{ARGV[0]},ou=Mail,dc=ray,dc=co,dc=jp", 'ldap.ray.co.jp')
end 
