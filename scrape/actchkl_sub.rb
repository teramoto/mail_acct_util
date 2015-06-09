#!/usr/local/bin/ruby 

# encoding : utf-8 
require './ldaputil.rb'
require 'csv' 
require 'logger'
require 'byebug' 

def prenc(ary)
  if $deb then 
    puts "#{ary.length} items in array"  
    inum = 0
    for i in ary do 
      inum += 1 
      puts "#{inum}:#{i} : (#{i.encoding})"
    end
  end 
end 

# byebug 
def get_last_line(file_path)
  last_line = "" 
  open(file_path) do |file|
    lines = file.read
    lines.each_line do |line|
      last_line = line
    end
  end
  return last_line.chomp
end 

def getpass_from_file(email,file,domain)
  puts "file = #{file}" if $deb
  csv = CSV.read(file) 
#  p csv  
  puts csv.size , csv.length 
#  puts csv.join(',')
#  byebug 
  if domain == "tc-max.co.jp" then
    ip = 0  # index for password 
    iem = 1 # index for email
  else 
    ip = 1  
    iem = 0
  end
  if domain =='wes.co.jp' then
    bb = email.split('@')
    id = bb[0] 
    csv.size.times do |i|
      if (csv[i][iem] == id) then 
        puts "Password=#{csv[i][ip]}" if $deb  
        return csv[i][ip] 
      end   
    end 
  else 
    csv.size.times do |i|
      if (csv[i][iem] == email) then 
        puts "Password=#{csv[i][ip]}" if $deb  
        return csv[i][ip] 
      end   
    end 
  end 
#  csv.eachline do |line|
#    puts line 
#  end 
  # cannot fined matched email
  return true 
end

def getname_from_file(email,file,domain)
  if domain == 'tc-max.co.jp' then 
    bb = email.split('@') 
    return bb[0]
  elsif domain == 'c.ray.co.jp' then 
    ip = 1
    iem = 0 
    inm = 2 
    csv = CSV.read(file)
    csv.size.times do |i|
      if (csv[i][iem] == email) then 
        puts "Name=#{csv[i][inm]}" if $deb  
        return csv[i][inm] 
      end 
    end  
  elsif domain == 'wes.co.jp' then 
    bb = email.split('@')
    id = bb[0] 
    ip = 1
    iem = 0
    inm = 3 
    ishain = 4 
    puts("#{email},#{file},#{domain}") if $deb
    csv = CSV.read(file)
    csv.size.times do |i|
      if (csv[i][iem] == id) then 
        puts "Name=#{csv[i][iem]}" if $deb
        return csv[i][inm] 
      end 
    end 
    return "" 
  end 
end

def getpassG(email,passfile,domain)
#  byebug
  if ($ldap == 'file') then 
    if (passwd = getpass_from_file(email,passfile,domain)) == true then 
      STDERR.puts "Cannot get password from file.#{email} "
      return "" 
    else 
      return passwd 
    end      
  elsif (passwd = getpass(email )) == true then 
    STDERR.puts "Cannot get password.#{email} "
    return "" 
  else 
    return passwd 
  end
end

