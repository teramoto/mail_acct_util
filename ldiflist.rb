#!/usr/local/bin/ruby

require './ldaputil.rb'

def ldaplist(domain, ldaphost,nth)
  if (domain == nil || ldaphost== nil) then
    STDERR.puts "Bad parameters," if $deb
    return nil
  end
  if nth < 0 then 
    retrun nil 
  end 
  case ldaphost
  when 'ldap.ray.co.jp'
    auth = { :method => :simple, :username => "cn=Manager,dc=ray,dc=co,dc=jp", :password => 'ray00' }
    treebase = 'ou=Mail,dc=ray,dc=co,dc=jp' 
  when 'wm2.ray.co.jp'
    auth = { :method => :simple, :username => "cn=Manager,dc=ray,dc=jp", :password => '1234' }
    treebase = 'ou=Mail,dc=ray,dc=jp' 
  end 
#  filter = Net::LDAP::Filter.eq('domainName' ,domain)
  filter = Net::LDAP::Filter.eq('domainName' ,domain)
#  filter = nil
  result = Array.new
  num = 0
#  begin
    Net::LDAP.open(:host=> ldaphost,:port=>389, :auth =>auth ) do |ldap|
#      p ldap
      enty = nil 
      ldap.search(:base => treebase, :filter => filter) do |entry|
#        p  entry if $deb
        num += 1
        if (nth == 0) ||(num == nth) then  
          str1 = Array.new
          puts "-->#{num}data."  if $deb
          entry.each do |attribute,values|
            puts( "#{attribute}:") if $deb 
            str2 = Array.new 
            str2.push(attribute.to_s)  
            values.each do |value|
              str2.push(value) #  += "," 
              # str2 += value.to_s 
            end
            puts str2.size if $deb 
            str1.push(str2) 
          end
          if (nth != 0) then
            return str1
          else  
            result.push(str1) 
          end 
        elsif num > nth then 
          STDERR.puts "nth over!#{nth}" 
          return -1 
        end 
      end
      if num < nth then 
        STDERR.puts "nth over!#{nth}" 
        return -1 
      end 
    end
#  rescue => ex
#    puts  ex if $deb
#    result.push(ex)
#     return result
#    retry
#     resume 
#  end 
#  p result if $deb 
  if num == 0 then
    puts "#{num}data." # if $deb
    return nil
  else
    puts "#{num}data." #  if $deb
    return result
  end
end

# $deb = true 
numx = ARGV[0].to_i
 
# p numx 
res = ldaplist('ray.co.jp', 'ldap.ray.co.jp', numx )
if res == -1 then 
  puts "number error! "
else 
#   puts res 
p res 
# puts res 
end
# puts res.size 
