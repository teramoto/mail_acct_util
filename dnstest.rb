#!/usr/local/bin/ruby

require 'resolv' 

hosts = [ "www.ray.co.jp", "www.yahoo.co.jp", "www.apple.com", "unexisthost.ray.co.jp" ]
dns = [ "ns.ray.co.jp", "ns1.ray.co.jp", "ns2.ray.co.jp", "ns3.ray.co.jp" ] 
dns2 = [ "202.213.241.227" , "202.213.241.225" ] 
dns3 = [ "210.150.40.2", "192.168.212.2", "192.168.200.200" ] 
class ResolvX < Resolv::DNS 
  def get_config_info() 
    return @config_info
  end
  def get_ns
    p @config_info 
    return @config_info # (:nameserver)
  end 
end 

def resolv( hostname, dns)
  print "looking up #{hostname}@#{dns.get_ns}.. " 
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
def check_dns_group(dns)  
  dns.each do |ns|
#    nn = Resolv::DNS.new(:nameserver => ns ) 
    nn = ResolvX.new(:nameserver => ns ) 
    if nn != nil then 
      nn.timeouts = 5 
      puts ns 
      nn.get_config_info

   # _info 
      $ns.push(nn)
      p nn 
#      p nn.getconf_info()
    end
  end 
end 

check_dns_group(dns2)
check_dns_group(dns3)
$ns.each do |d|
  hosts.each do |hs|
    resolv( hs, d)
  end 
end 

#resolv("www.ray.co.jp")
#resolv("www.yahoo.co.jp")
#resolv("www.apple.com")
#resolv("wsss.ray.co.jp") 
 
