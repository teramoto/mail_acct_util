require 'net/ldap'
require 'cgi'
require './ldaputil.rb'
require 'optparse'

# from optparse import OptionParser

puts "editing forward address.."
usage= "forwardaddress, address to add/del, cmd (add,del,chk)" 

## main start
#opt = OptionParser.new # (usage = usage)
opt  = OptionParser.new(usage=usage)
OPTS = {}
Version = '0.2' 
deb = false 
opt.on('-d', 'debug mode ') { deb = true }
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

#bb = fwaddr.split('@') 
#if bb == nil then 
#  puts "invalid address #{fwaddr}" 
#  exit -1
#elsif $udomain.include?(bb[1]) then 
#  puts "domain #{bb[1]}" 
#  domain = "wm2.ray.co.jp" 
#else 
#  puts "unsupported domain #{bb[1]}" 
#  exit -1 
#end
$ldap1 = getldap(fwaddr) 

if $cmd == nil || $cmd.length < 1 then
  $cmd = "chk" 
end 
byebug if deb
if (result=getfwd(fwaddr, $ldap1)) == true then 
  puts result 
  STDERR.puts "Error:fwd adress #{fwaddr} not exsits."
else 
  result = fwedit(fwaddr, $traddr[0], $cmd, $ldap1)
  puts "result = #{result.join(',')}" 
  p result if deb
#  1.upto($traddr.size-1) do |tt| 
#    byebug if deb 
#    result=  fwedit(fwaddr, $traddr[tt], $cmd, $ldap1)
#    puts "result =#{result}"  
#  end
end 

