#!/usr/local/bin/ruby

require 'net/ldap'
require 'cgi'
require './ldaputil.rb'
require 'optparse'
require 'logger' 

puts "deleting wifi uid."

## main start
opt = OptionParser.new
OPTS = {}
Version = '0.1' 
deb = false 
opt.on('-d ', 'debug mode ') { deb = true }

puts ARGV[0] ,ARGV[1], ARGV[2]
rr = opt.parse!(ARGV)
#puts getfwd ARGV[0]
ldapdel("uid=#{ARGV[0]},ou=Services,dc=ray,dc=co,dc=jp")
