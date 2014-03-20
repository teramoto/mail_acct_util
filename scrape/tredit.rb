#!/usr/local/bin/ruby 

require 'csv'

ARGV.each do |addr|
  puts addr, addr.length
end
reader = CSV.open('tcmacct.csv','r')
header = reader.take(1)[0] 
p reader 

def addmail(csv,  email) 
  adlen = (email.length) +1 
  csv.each do |row| 
    linelength = 0 
    if ( /^tc[0-9]/ =~ row[0] ) && (row[1]=='false') then 
      print "#{row[0]} ==>" 
#       puts row.length
      2.upto(row.length-1) do |num|  
#        puts "num= #{num}" 
        print "#{row[num]},"  #"#{row[num].length} " 
        linelength += (row[num].length + 1)
      end 
      linelength -= 1 
      if linelength + adlen <= 100 then 
        row.push(email)
        puts "#{email} added!" 
        p row 
        return  
      else 
        puts "cannot add #{email}" 
      end 
      puts "linelength = #{linelength}"  

    end  
#  puts row
  end 
end 

ARGV.each do |addr|
  addmail(reader, addr)
end 
CSV.open("temp.csv", "wb") do |csv|
  csv << header
  csv << reader 
end

reader.each do |row|
  if ( /^tc[0-9]/ =~ row[0]) then 
    row.each do  |i|
      print "#{i}," 
    end 
    puts 
  end 
end 

reader.each do |row|
  puts row 
end   
