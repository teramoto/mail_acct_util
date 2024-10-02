#!/usr/local/bin/ruby

require './ldaputil' 

fn = 'tt.txt' 
if ARGV[0] != nil then 
  fn = ARGV[0]
end 
#option = 'ijla' 
#option = 'j' 
option = "dijla" 
lnum = 0 
File.open(fn) do |f|
  f.each do |line|
   # p line
    l1 = line.chomp
    if valid_email_address?(l1) then 
      # puts "./actchkl2.rb #{l1} -xyidla"
      if lnum == 0 then 
        puts `ruby actchkl2.rb #{l1} -xy#{option}u`
      else 
        puts `ruby actchkl2.rb #{l1} -xy#{option}`
      end 
      lnum += 1
    end 
  end
end
STDERR.puts "#{lnum}address processed." 
