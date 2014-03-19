#!/usr/local/bin/ruby


lnum = 0 
File.open('tt.txt') do |f|
  f.each do |line|
   # p line
    l1 = line.chomp
    # puts "./actchk.rb #{l1} -xyidla"
    if lnum == 0 then 
      puts `ruby actchk.rb #{l1} -xyijlau`
    else 
      puts `ruby actchk.rb #{l1} -xyijla`
    end 
    lnum += 1
  end
end
STDERR.puts "#{lnum}address processed." 
