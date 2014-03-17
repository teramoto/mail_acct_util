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
$traddr = Array.new

# puts ARGV[0] ,ARGV[1], ARGV[2]
rr = opt.parse!(ARGV)
puts ARGV.size 
p ARGV 
ARGV.each do |arg|
  p arg
  puts arg.size 
  if valid_email_address?(arg) then 
    $traddr.push(arg)
  elsif arg.length == 3 then 
    $cmd = arg 
  end 
end 
p $traddr.size 
puts "fwaddr = #{$traddr[0]}" 
1.upto($traddr.size-1) do |t|
  puts $traddr[t]
end
if $cmd == nil then 
  $cmd = "chk" 
end 
puts "cmd = #{$cmd}" 
## exit 0
case $traddr.size 
when 0
  STDERR.puts "need forward address "
  exit -1
when 1 
  fwaddr  = $traddr[0]
  puts "set fwaddr = #{fwaddr}" 
  modaddr = "   " 
else
  fwaddr  = $traddr[0]
  modaddr = $traddr[1]
  puts "set fwaddr = #{fwaddr}" 
end 
puts "fwaddr = #{fwaddr}" 

if $cmd == nil || $cmd.length < 1 then
  $cmd = "chk" 
end 
if (result=getfwd(fwaddr)) == true then 
  puts result 
  STDERR.puts "Error:fwd adress #{fwaddr} not exsits."
else 
  1.upto($traddr.size-1) do |tt| 
    result=  fwedit(fwaddr, $traddr[tt], $cmd)
    puts result 
  end
end 

