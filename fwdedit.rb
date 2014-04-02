#!/usr/local/bin/ruby

require 'net/ldap'
require 'cgi'
require './ldaputil.rb'
require 'optparse'

puts "editing forward address.."
puts "forwardaddress, address to add/del, cmd (add,del,chk)" 

## main start
opt = OptionParser.new
OPTS = {}
Version = '0.2' 
deb = false 
opt.on('-d ', 'debug mode ') { deb = true }
traddr = Array.new

# puts ARGV[0] ,ARGV[1], ARGV[2]
rr = opt.parse!(ARGV)
puts ARGV.size 
modad2 = Array.new 
p ARGV 
case ARGV.size 
when 0
  STDERR.puts "need forward address "
  exit -1
when 1 
  fwaddr = ARGV[0]
  modaddr = "   " 
  cmd = "chk" 
when 2 
  fwaddr = ARGV[0]
  modaddr = ARGV[1]
  cmd = "chk"
when 3 
  fwaddr = ARGV[0]
  modaddr = ARGV[1]
  cmd = ARGV[2]
when 4..9999
  fwaddr = ARGV[0]
  modaddr = ARGV[1]
  cmd = ARGV[2]
  if cmd == "add" then 
    3..ARGV.size do |i| 
      if valid_email_address?(ARGV[i-1]) then 
        modad2.push(ARGV[i-1])
      end 
    end
  end
else 
  STDERR.puts "At least need forward address." 
end 

if cmd == nil || cmd.length < 1 then
  puts  "please specify command"
  exit -1 
end 
$ldap = getldap(fwaddr) 
p $ldap
if $ldap == true then 
  puts "Can't get ldap server!" 
  exit -1
end 
if (result=getfwd(fwaddr,$ldap)) == true then 
  puts result 
  STDERR.puts "Error:fwd adress #{fwaddr} not exsits."
else 
  if modaddr.index(',') == nil then 
    result=  fwedit(fwaddr, modaddr, cmd)
    puts result 
  else 
    ppk = modaddr.split(',')
    ppk.each do |ad|
      result = fwedit(fwaddr,ad, cmd)
      puts result 
    end
  end
end 

