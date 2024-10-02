#!/usr/local/bin/ruby

require 'net/ldap'
require 'cgi'
require './ldaputil.rb'

puts ARGV[0] 

res = getpass ( ARGV[0] )
p res
puts res
puts res == true
puts res == false 
