#!/usr/local/bin/ruby

require './ldaputil.rb'

def ldapdisplay(domain, treebase,ldaphost)
  if treebase== nil then
    puts "Bad parameters," if $deb
    return nil
  end
  if (treebase.length< 1) then
    puts "Bad parameters," if $deb
    return nil
  end
  auth = { :method => :simple, :username => "cn=Manager,dc=ray,dc=co,dc=jp", :password => 'ray00' }
#  filter = Net::LDAP::Filter.eq('domainName' ,domain)
  filter = Net::LDAP::Filter.eq('domainName' ,domain)
#  filter = nil
  result = Array.new
  num = 0
#  begin
    Net::LDAP.open(:host=> ldaphost,:port=>389, :auth =>auth ) do |ldap|
      p ldap
      enty = nil 
      ldap.search(:base => treebase, :filter => filter) do |entry|
#        p  entry if $deb
        num += 1
        str1 = String.new
#        puts "#{num}data."  if $deb
        entry.each do |attribute,values|
#          puts( "#{attribute}:")
          str1 = attribute.to_s  
          values.each do |value|
            str1 += ": " 
            str1 += value.to_s 
          end
          puts str1 
          result.push(str1) 
        end
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
    return nil
  else
    puts "#{num}data."  if $deb
    return result
  end
end

$deb = true 
# treebase = 'dc=ray,dc=co,dc=jp' 
treebase = 'ou=Mail,dc=ray,dc=co,dc=jp' 
# treebase = 'ou=Services,dc=ray,dc=co,dc=jp' 

res = ldapdisplay('ray.co.jp', treebase,'ldap.ray.co.jp')
puts res 
