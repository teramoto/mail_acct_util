#!/usr/local/bin/ruby 

require 'optparse'

pass = "" 
tradd = Array.new 

opt = OptionParser.new
opt.on('-a') { |v| p v}
opt.on('-t VAL', 'set Type. T -> transfer address' ) { |v| p v }
opt.on('-p VAL', 'password') { |v| pass= v }
opt.on('-c VAL', 'assign transfer addresss') { |v| tradd.push(v) }


opt.parse!(ARGV)
#p ARGV
if ARGV.length < 2 then 
  puts "need tr-mailaddress and description of address" 
  exit -1 
end 

email = ARGV[0] 
trname = ARGV[1] 

if email.index('@') == nil then 
  puts ("Wrong wmail address")
  exit -1 
else 
  pp = email.split('@')
end

id = pp[0]
domain = pp[1] 
STDERR.puts "#{id} #{domain}" 
if domain == 'ray.co.jp' then
  uid = id 
else 
  uid = email
end 


  puts "# TRaddress : #{email}"
  puts "dn: uid=#{uid},ou=Mail,dc=ray,dc=co,dc=jp"
  puts "objectClass: mailUser"
  puts "cn: #{trname}" 
  puts "sn: #{trname}"
  puts "uid: #{uid}"
  puts "userPassword: #{pass}"
  puts "homeDirectory: /data/home/vmail/#{domain}/#{id}"
  puts "mailDir: #{domain}/#{id}/Maildir/"
  puts "mail: #{email}"
  $quota = 2**8
  puts "mailQuota: #{$quota}"
  puts "accountKind: 2"
  print "mailForward: " 
  if tradd.length > 0 then 
    print (tradd.join(','))
  end 
  print "\n"
  puts "wifiuid: #{uid}" 
  puts "accountActive: TRUE"
  puts "domainName: #{domain}"
  puts "transport: virtual"


