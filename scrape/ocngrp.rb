#!/usr/local/bin/ruby 

require 'csv'
$deb = false   
tcmacct = CSV.read("tcmacct.csv") 
p tcmacct if $deb 
#puts tcmacct.length
len = tcmacct.length
puts len if $deb 

mojisuu = Array.new 
moji = Array.new 

for n in  1..len-1 
  if /^tc[0-9]+/ =~ tcmacct[n][0] then 
    puts tcmacct[n][0] if $deb 
    $llen = 0
    for m in 2..tcmacct[n].size-1
      print n if $deb 
      p tcmacct[n] 
      $llen += tcmacct[n][m].length  
      mojisuu.push tcmacct[n][m].length 
      moji.push tcmacct[n][m] 
      if (m !=2 )& (m != tcmacct[n].length)  then 
        $llen += 1
      end
      puts "#{tcmacct[n][m]},#{$llen}" if $deb 
    end 
  end  
end

## additional address to set. 
sdd1 =Array.new( ["eki@tc-max.co.jp","nakano@tc-max.co.jp","oikawa@tc-max.co.jp","makida@tc-max.co.jp","c-takezaki@ray.co.jp"])
p sdd1 if $deb 
sdd1.each do |p|
  moji.push p 
  mojisuu.push p.length
end 
p mojisuu if $deb 
mojisuu2 = mojisuu.sort 
p mojisuu2 if $deb 
p mojisuu2 - [24] if $deb 
puts mojisuu2.inject(:+) if $deb 
p moji if $deb 
## calculate to fit container of 100 ...
mrseult = Array.new 
len = 0 
s = 0 
blen = '@tcmax.co.jp'.length + 1 
puts "base length = #{blen}" 
groups = Array.new 
tbox = Array.new 
while !(mojisuu2.empty?)  
  while (len <= (100-blen))
    if mojisuu2.empty? then 
      break
    end  
    num = mojisuu2.pop 
    if (len + num) <= 100  
      s += 1 
      len += num 
      tbox.push(num) 
      if s > 1 then 
        if len < 100 then 
          len += 1 
        end  
      end 
    else ## exceed limit...
      mojisuu2.push(num)
      break 
    end 
  end 
  p tbox 
  puts tbox.inject(:+) 
  groups.push(tbox.dup) 
  tbox.clear
  len= 0
  s=0 
  p groups 
end 
## output groups.... 
lines = Array.new 
n1 = 1 
groups.each { |x| 
  print "tc#{n1}@tc-max.co.jp:"
  s1 = 0 
  x.each { |y|
    moji.each {|m| 
      if m.length == y then
        s1 += 1 
        lines.push(m)  
        if s1 > 1 then 
#          print ","
        end 
#        print m 
        moji -= Array.new([ m ] )
        break
      end
    } 
#    p y
#    p lines 
  }
  puts lines.join(",")
#  print "\n" 
  lines.clear 
  n1 += 1
}



