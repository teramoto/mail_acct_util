#!/usr/local/bin/ruby

require 'csv'

trfile = File.open("kgtrans.csv","w")
actfile = File.open("kgacct.csv","w")
dmfile = File.open("kgdom.csv","w")
infile = ARGV[0]
$passfile = CSV.read("tcmpass.csv")
$tcall = Array.new
# p $passfile 
$dst = Time.now.to_s
puts "Processing file:#{infile}"
# actfile.write("\"処理区分\",\"アカウ$ント名\",\"パスワード\",\"備考\",\"メールボックス容量\",\"メールボックス使用量\",\"パスワード変更設定権限\",\"転送設定設定権限\",\"自動返信設定権限\",\"セレクトドメインメール設定権限\"\n")
def getacct(ary)
  tmp =  ary.split('@')
  p tmp if $deb
  tmp[0] = tmp[0].sub("_", "-" )
  if tmp[1] == 'tc-max.co.jp' then
    return tmp[0]
  else 
    return nil
  end
  puts "account error!"
  p ary
  exit -1
end
def getpass(email)
  p $passfile if $deb 
  $passfile.each do | line |
    if line[1] == email then
      if ((line[0] == nil)|| (line[0].length < 2))  then 
        return "Ray12345" 
      else 
        return line[0]
      end   
    end 
  end 
  puts "Error:password for #{email} not find.." 
  return "Ray12345" 
#   p $passfile[0]
end   
def gettrans(line)
  s = line.size 
  i = 2 
  rs = Array.new 
  p line 
  while i < s 
    rs.push(line[i])
    i += 1 
  end 
  p rs.join(",")
  return rs.join(",")
end 

CSV.foreach(infile) do |row| 
  p row 
  p row[0].length
  if row[0].length > 2 then 
     ## write account information
    act = Array.new(10)
    act[0] = "1"  # 1:追加 2:変更 3:削除
    act[1] = "tcm." + getacct( row[0])   # max 16 letters.... 
    if act[1].length >16 then 
      puts "アカウント名が長過ぎます．#{act[1].length}" 
      exit -1 
    end 
    act[2] = getpass row[0]
    act[3] = "set by kagoyagen.rb" # remark = "" 
    act[4] = "300"  # boxsize in mb
    act[5] = $dst    # user area :
    act[6] = "2"   # passchange = %("2")
    act[7] = "2"   # transset = $("2")
    act[8] = "2"   # 自動返信設定可否
    act[9] = "0"   # セレクトドメイン設定可否
    actfile.puts( "\"" + act.join("\",\"") + "\"") 
    #  actfile.write(%( "1"    
    
    # write 独自ドメインメール設定
    org = Array.new(3)
    org[0] = "1"  # 追加
    org[1] = row[0]
    org[2] = act[1]
    dmfile.puts( "\"" + org.join("\",\"") + "\"")
  end 
  #  write transfer setting
  puts "rowsize = #{row.size}"   
  if (row.size > 2) then 

    if /tc[0-9]+@tc-max.co.jp/ =~ row[0].to_s then 
      puts "tcadr:#{row[0]}" 
      $tcall.push(gettrans(row))
    elsif /tc[a-z]@tc-max.co.jp/ =~ row[0].to_s then 
      puts "tcadr:#{row[0]}" 
    elsif row[0] == "alltc@tc-max.co.jp" then 
     puts "suspend all-tc" 
    else 
      trs = Array.new(5)
      trs[0] = act[1]  # account
      trs[1] = $dst   # user area 
      trs[2] = gettrans(row) 
      trs[3] = "1"   # 転送後削除
      trs[4] = "1"   # 迷惑メールを転送しない
      trfile.puts( "\"" + trs.join("\",\"") + "\"") 
  
    end 

  end   
#  puts row 
end
if $tcall.size > 1 then 
  trs = Array.new(5)
  trs[0] = "tcm.all-tc" 
  trs[1] = $dst
  trs[2] = $tcall.join(",") 
  trs[3] = "1" 
  trs[4] = "1" 
  trfile.puts( "\"" + trs.join("\",\"") + "\"") 
end 

dmfile.close
actfile.close
trfile.close

