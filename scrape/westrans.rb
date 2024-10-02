#!/usr/local/bin/ruby 

#
# WebArena から取得した転送リストから
# 中間転送アドレスを展開して表示します。
# WebArena の転送テーブルには10個のアドレスしか
# 記述できないため、中間に副アドレスを作成して解決しています。
# 副アドレスはzz_ から始まる物として、区別しています。
# wes_trans.txt を読込んでzz_ から始まるアドレスを展開します。
# 現在はリスト内の転送アドレスが参照されている物を展開する。
#

require 'optparse'
require '../ldaputil.rb' 
require 'tracer' 
# Tracer.on
$db = false 
opt = OptionParser.new
Version = "0.1" 
opt.on('-a xxx@ray.co.jp', 'set email address') { |v| p v }
$arg = opt.parse(ARGV)

$body = Array.new
toaddr = Array.new
traddr = ""
File.foreach($arg[0]) do |line|
  line.chomp! 
  # leading 2 spaces indicate address to go 
  if ( /^[\s]*[0-9]*:/ =~ line) then 
    # adress to transfer 
    p line if $db
    puts "toaddress: #{$'}" if $db 
    toaddr.push($')
    p toaddr if $db 
  elsif (/:/ =~ line) then 
    puts "transfer address #{$`}" 
    if traddr.length > 0 then 
#      $body.push([traddr,toaddr.join(',')])
      p [traddr,toaddr] if $db
      $body.push([traddr,toaddr])
      p $body[$body.size - 1] if $db  
      traddr = "" 
      toaddr = Array.new 
      p traddr if $db
      p toaddr if $db
    end 
    traddr = $` 
  else 
    puts "Invalid! #{line}" 
    p line if $db
  end 
end
## finish.. 
begin 
    puts "transfer address #{traddr}" if $db
    if traddr.length > 0 then
#      $body.push([traddr,toaddr.join(',')])
      p [traddr,toaddr] if $db
      $body.push([traddr,toaddr])
      p $body[$body.size - 1] if $db
      traddr = "" 
 #     toaddr.clear
      p traddr if $db
      p toaddr if $db
    end
end 
## under dev 

def tr_rewrite(emailarry)
  puts "tr_rewrite" if $db
  p emailarry  if $db
  rs = Array.new
#  p emailarry.class 
  if (String === emailarry) then 
    str = emailarry 
    emailarry = Array.new
    emailarry.push(str)
  end
# Tracer.on  
  emailarry.each do |addr|
    if /@wes.co.jp$/ =~ addr then 
      addr = $`
      p addr if $db
    elsif /@/ =~ addr then 
      rs.push(addr) 
#      break   
    end 
    p addr if $db
  # wes.co.jp or no domain..
    for i in 0..($body.size-1) do 
#      puts "key #{addr}" 
      p addr if $db
      p $body[i][0] if $db
# Tracer.on 
      if $body[i][0] == addr then 
        p $body[i][1] if $db
        puts "tr_rewrite match : #{addr} : #{$body[i][0]} " if $db
        rs +=  tr_rewrite($body[i][1])

        puts "tr_rewrite result :" if $db
        p rs if $db
        puts "tr_rewrite result size= #{rs.size}" if $db
#         break 
      else  
        puts "tr_rewrite diff : #{addr}: #{$body[i][0]} " if $db
      end
# Tracer.off
    end
  end 
  puts "tr_rewrite result :" if $db
  p rs if $db
  puts "tr_rewrite result size= #{rs.size}" if $db
# Tracer.off  
  return rs 
end 

#
# 転送アドレスを展開する
#
def praddr(emarry)
  puts "<-- praddr --- #{emarry.length}" if $db
  rs = Array.new 
  p emarry if $db
  emarry.each do |addr|
    tm = tr_rewrite(addr)
    p tm.class if $db
    p tm  if $db
    if tm.size == 0 then 
      rs.push(addr)
    else
      p tm  if $db
      rs += tm
    end 
  end
  puts "--- praddr --> #{rs.length}" if $db
  p rs if $db
  p rs.flatten if $db
  return rs 
end 

def pradrchk( adrs)
  adr = Array.new
  kk = Array.new 
  adr.push(adrs) 
  kk = praddr(adr)
  p kk if $db
  puts "kk:size=#{kk.size}"  if $db
  kk1 = kk.join(',')
  puts  "pradr: src:#{adrs} result: #{kk1}"
  puts  " #{kk.size} addresses."  
end

puts "#{$body.size} Transfer address defined." 
# Tracer.on 

pradrchk("j-hibino@wes.co.jp")
# pradrchk("j-hibino") 
pradrchk("wes-all@wes.co.jp") 
pradrchk("zz_wes-3f_1") 
pradrchk("zz_wes-3f_2") 
pradrchk("zz_wes-3f_3") 
pradrchk("zz_wes-3f_4") 
pradrchk("zz_wes-3f_5") 
# puts praddr(["wes-all"])

#p $body  
#p $body.index('j-hibino')  
exit 
$body.each do |elm| 
  puts "$body elements." 
  p elm 
#   p elm1 
  print "#{elm[0]} => " 
  elm[1].each do |e| 
    puts praddr(e)
  end
  print "\n" 
end 
 
