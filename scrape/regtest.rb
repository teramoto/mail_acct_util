
ss = "j-hibino@wes.co.jp" 

if /^j-hibino/ =~ ss then 
  puts("match")
else 
  puts("not match")
end 
if /$p/.match(ss) then 
  puts("match")
else 
  puts("not match")
end 

puts "$\` #{$`}" 
puts "$\' #{$'}"
s1 = "surrealtest" 
s2 = "testtawreal" 
if /real$/.match(s2) then 
  puts "match" 
else 
  puts "not match" 
end 
