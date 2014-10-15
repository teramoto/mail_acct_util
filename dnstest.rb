#!/usr/local/bin/ruby

require 'resolv' 

hosts = [ "www.ray.co.jp", "www.yahoo.co.jp", "www.apple.com", "wsss.ray.co.jp" ]
dns = [ "ns.ray.co.jp", "ns1.ray.co.jp", "ns2.ray.co.jp", "ns3.ray.co.jp" ] 
dns2 = [ "202.213.241.227" , "202.213.241.225" ] 

def resolv( hostname, dns)
  print "looking up #{hostname}@#{dns}.. " 
  res = "" 
  dns.each_address( hostname) { | n| 
    puts n
    res += n.to_s 
  }
  if res == "" then 
    puts "X" 
  end 
  return res 
end
$ns = Array.new 
p = 0 
dns2.each do |ns|
  nn = Resolv::DNS.new(:nameserver => ns ) 
  if nn != nil then 
    $ns.push(nn)
  end
end 

$ns.each do |d|
  hosts.each do |hs|
    resolv( hs, d)
  end 
end 

#resolv("www.ray.co.jp")
#resolv("www.yahoo.co.jp")
#resolv("www.apple.com")
#resolv("wsss.ray.co.jp") 
 
