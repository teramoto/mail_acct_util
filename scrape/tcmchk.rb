#!/usr/local/bin/ruby 

require 'csv'
require '../ldaputil.rb' 
# puts "hello"
$psar = CSV.read('tcmpass.csv')
# p $psar 
$psar.each do | ar| 
# p ar
end
puts $psar[0][0]
puts $psar[0][1]

def getpass_f(uid)
  $psar.each do |ar|
#     p ar  
    if ar[1] == uid then 
      return ar[0]
    end 
  end
  return nil 
end
  
CSV.foreach("tcmacct.csv") do |row|
#  p row 
  # check for pop account
  if row[1] == 'true' then 
##    puts row[0] ## email  
    ## seach for password 
    ps = getpass_f(row[0]) 
    if ps == nil then 
      puts "no password found for #{row[0]}"
    else
      puts "#{row[0]}:#{ps}"  
# def ldapout(uid, mail, passwd, sei, mei, domain, f_name, name, shain )
    nm = row[0].split("@") 
    mail = row[0] 
    puts mail 
    result = ldapout( mail, nm[0] , ps, nm[0], nm[0], 'tc-max.co.jp' , nm[0], nm[0], 9999) 
    p result 
    end 
#    psx = getpass(row[0])
#     puts "ldap password(#{row[0]}) = #{psx}"  
  elsif row[1] == 'false' then 
    
    puts "#{row[0]} is transfer address. skipping..."
  else 
    puts "illegal data #{row[0]}" 
  end
end

