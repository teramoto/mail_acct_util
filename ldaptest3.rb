#!/usr/local/bin/ruby

require 'net/ldap'
require 'cgi'
require './ldaputil.rb'
require 'optparse'

## homeDirectory: /data/home/vmail/ray.co.jp/ken
## mailDir: ray.co.jp/ken/Maildir/


ay,dc=co,dc=jp
objectClass: mailUser:

puts "editing forward address.."
puts "forwardaddress, address to add/del, cmd (add,del)" 

## main start
opt = OptionParser.new
OPTS = {}
Version = '0.1' 
deb = false 
opt.on('-d ', 'debug mode ') { deb = true }

puts ARGV[0] ,ARGV[1], ARGV[2]
rr = opt.parse!(ARGV)
#puts getfwd ARGV[0]
addattr(ARGV[0],ARGV[1],ARGV[2])

 
