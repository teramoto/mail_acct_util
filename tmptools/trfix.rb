#!/usr/local/bin/ruby

require 'net/ldap'
require 'cgi'
require './admin/ldaputil.rb'
require 'optparse'

## homeDirectory: /data/home/vmail/ray.co.jp/ken
## mailDir: ray.co.jp/ken/Maildir/



puts "read mail address list form traddr.txt and add Maildir information to forward address.."

## main start
opt = OptionParser.new
OPTS = {}
Version = '0.1' 
deb = false 
opt.on('-d ', 'debug mode ') { deb = true }

puts ARGV[0] ,ARGV[1], ARGV[2]
rr = opt.parse!(ARGV)
#puts getfwd ARGV[0]
## traddr.txt をよみこむ。
File::open('traddr.txt','r') do |file|
  file.each_line do |line|
    $uid = "" 
    puts line 
    $pp = line.split(" ")
    p $pp  ## "maii: xxxx@ray.co.jp" pp[0]="mail:" pp[1]=email address  
    $aa = $pp[1].split('@')  ## aa[0] =xxxx, aa[1]= ray.co.jp  
    p $aa 
    $domain = $aa[1]
    $id = $aa[0] 
    case $domain 
    when 'ray.co.jp' then 
      $uid = $aa[0]
    when 'tera.nu','plays.co.jp','digisite.co.jp','tera.nu' then 
      $uid = $pp[1]
    else 
      p $pp
      exit 0
    end
    ## make ldap uid for mail system 
    if (res = ldapvalue('uid', $uid, 'homeDirectory' )) then 
      if res.length < 3 then 
        result = addattr( $uid, 'homeDirectory', "/data/home/vmail/#{$domain}/#{$id}" )
        puts result
      end
    end 
    if (res = ldapvalue('uid', $uid, 'mailDir')) then 
      if res.length < 3 then ## add Maildir information...... 
        result1 = addattr( $uid, 'mailDir', "#{$domain}/#{$id}/Maildir/" )
        puts result1 
      end 
    end 
  end
end 
exit 0

if  res = ldapvalue('uid' , ARGV[0], ARGV[1]) then 
  puts "true"
  puts res 
  puts res.length 
else 
  puts "false" 
end 
exit 0

addatt(ARGV[0],ARGV[1],ARGV[2])

 
