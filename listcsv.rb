#!/usr/local/bin/ruby


File.open('tt.txt') do |f|
  f.each do |line|
   # p line
    l1 = line.chomp
    puts "./actchk.rb #{l1} -xyidla"
    `ruby actchk.rb #{l1} -xyidla`
  end
end
