#!/usr/local/bin/ruby 

require 'pg'
require 'ldaputil' 

# mail = ARGV[0] 

#
# access dnetdb and return somedata
# input: email address 
# output: mail,name, userid (shain# usually) ,id  
#
def dnetmailinfo(mail)
  if ! valid_email_address?(mail) then 
    return(-1) 
  end 
  connection = PG::connect(:host => "intra.ray.co.jp", :user => "dnet", :password => "dnetdb", :dbname => "dnetdb")
  if connection == nil then
    STDERR.puts "cannot connect"
    return(-1)
  end
  # p connection 
  res = Array.new 
  begin
    # connection を使い PostgreSQL を操作する
    mailstr= "#{mail}"
    result = connection.exec("SELECT name,mail,defgroup,userid,id,word FROM tm_user where mail like '#{mailstr}' " ) 
    begin
      p result 
      puts result.ntuples  # ヒットした行
      puts result 
    end if $deb 
# 各行を処理する
    result.each do |tuple|
      begin 
        puts "name:#{tuple['name']}" 
        puts "mail:#{tuple['mail']}"
        puts "defgroup:#{tuple['defgroup']}" 
        puts "userid:#{tuple['userid']}" 
        puts "id:#{tuple['id']}" 
        puts "word:#{tuple['word']}" 
      end if $deb 
      res.push(tuple['mail'])
      res.push(tuple['name'])
      res.push(tuple['userid'])
      res.push(tuple['id']) 
    end 
  # ...
  ensure
    # データベースへのコネクションを切断する
    connection.finish
  end
  return res 
end

dnetmailinfo(ARGV[0]) 
