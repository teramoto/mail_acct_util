#!/usr/local/bin/ruby

require 'net/ldap'
require 'cgi'
require './ldaputil.rb'
require 'optparse'

## homeDirectory: /data/home/vmail/ray.co.jp/ken
## mailDir: ray.co.jp/ken/Maildir/



puts "check forward address.."

## main start
opt = OptionParser.new
OPTS = {}
Version = '0.1' 
deb = false 
opt.on('-d ', 'debug mode ') { deb = true }

puts ARGV[0] ,ARGV[1], ARGV[2]
rr = opt.parse!(ARGV)

result =  getfwd ARGV[0]
if result == true then 
  STDERR.puts "error in #{ARGV[0]}" 
end
p result 
 
