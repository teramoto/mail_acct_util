# encoding: utf-8 

require 'rubygems'
require 'byebug' 
require 'mechanize' 
require 'openssl'
require 'kconv'
require 'cgi'
require 'date' 
require 'mail'
require 'nkf' 
require './humanreadable.rb' 

#$deb = true 
#$fchk = true 

$addr = Array.new 
$emdata = Array.new
I_KNOW_THAT_OPENSSL_VERIFY_PEER_EQUALS_VERIFY_NONE_IS_WRONG = nil
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
puts Mechanize::VERSION if $deb 
agent =  Mechanize.new do |a|
	a.open_timeout = 60
#        a.ca_file = 'GTE_CyberTrust_Global_Root.pem'
#        a.ca_file = '/etc/pki/tls/cert.pem' 
        a.ca_file = '/etc/pki/tls/certs/ca-bundle.crt' 
        a.verify_mode = OpenSSL::SSL::VERIFY_NONE
end

def trexp(e)
  i = $addr.index(e)
  em = $emdata[i]
  rs = Array.new  
  em1 = em.split(',') 
  if (em1.size >3) then
    em1.shift ; em1.shift 
    em1.each do |e| 
      rs.push e
    end
  end
  puts "#{e}=>#{rs.to_a}" 
  return rs 
end 

ln= 1 
mn = 0
tdn = 0  
addr = ""
address = ""  
comment = "" 
capa = -99
used = -99 

# fromaddr, Array toaddr , Array ccaddr ,  Array body 
$adminaddr = [ "niijima@c.ray.co.jp", "kano@c.ray.co.jp", "ken@ray.co.jp"  ]
$dbuser = [ "ken@ray.co.jp" ] 
$noreport = [ "ken@c.ray.co.jp" ]

def send_mail(fromaddr,toaddr, ccaddr , subject, body) 
  mail = Mail.new
  mail.charset = 'ISO-2022-JP' 
  mail.from = fromaddr 
  if $deb || $fchk then # for test 
    mail.to = 'ken@ray.co.jp' 
  else # to the real world
    mail.to = toaddr.join(",")
    if ($noadm == nil || $noadm== false) then 
      mail.cc = (ccaddr + $adminaddr).join(',') 
    else 
      mail.cc = ccaddr.join(',') 
    end
    puts mail.cc 
  end 
  STDERR.puts "sending report via email......" 
  body1 = body # .join(',')
  mail.body    = NKF.nkf('-Wj', body1).force_encoding("ASCII-8BIT")
  mail.subject = NKF.nkf('-WMm0j', subject).force_encoding("ASCII-8BIT")
  begin 
    if $deb then 
      puts mail.body
      mail.deliver 
    else 
      mail.deliver 
    end
  rescue => ex
    p ex
  end 
end

def warnuser(address, acct, ratio, used, capa , comment) 
  puts address if $deb 
  if $noreport.include?(address) then 
    return 
  end 
  body= <<EOS
#{address}のメールボックスは現在#{ratio}% が使用されています。(総容量#{capa}中使用容量#{used}) 
80% を超えますと大きいメールが受信できなくなる等のトラブルが発生しますので、
メールサーバーの該当メールボックス内の不要なメールの削除をお願い致します。
削除はメーラーの設定、Webメールから行うことができます。
WebメールのURL：https://secure.sakura.ad.jp/rscontrol/?webmail=1
ユーザーID:#{acct}
パスワード:メールのパスワード

WebMailマニュアル:https://help.sakura.ad.jp/app/answers/detail/a_id/2255
EOS

#  $deb = true 
  send_mail('noreply@ray.co.jp',Array[address], Array['networkteam@ray.co.jp']  , 'メール残容量にご注意ください', body)
end

#  p body 
# puts agent.ca_file
# puts agent.cert
# puts agent.key
# puts agent.pass
# puts agent.verify_callback

## initial setup 
url =  'https://secure.sakura.ad.jp/rscontrol/'
id = 'cray1.sakura.ne.jp' 
pss = '6v8kntxnp9'
dom = 'c.ray.co.jp' 

page = agent.get(url)
ff = page.form(:name =>'login')

# set ID and password 
ff.field_with(:name => 'domain').value = id
ff.field_with(:name => 'password').value = pss

page = ff.submit() 


p2 = page.link_with(:text => 'ユーザ管理').click  
#p p2 
userdata = p2.search('table[@class = "viewbox"]').search('tr')
puts userdata.length if $deb  
num = 0
File.open('craysakura.csv', "w") do |file|
  userdata.each do |tr|
    puts "tr---" if $deb 
   # p tr if $deb 
    if tr == nil then 
      break 
    end 
#    puts "#{num}:#{tr}" 
    puts "#{num} ---------------------" if $deb
#    if num > 35 then 
#      byebug 
#    end 
    if tr != nil && (tx = tr.search('font')) then 
      # byebug
    
      td = tr.search('td')  
      if (td != nil) && (td.size > 0) then 
        if td[0].search('span') != nil then 
          desc = td[0].search('span').text
        else 
          desc = ""
        end 
        user = td[0].search('font').text 
#        puts desc , user
        mail = td[1].text
        ftp = td[2].text
        usedt = td[3].text.rstrip!.lstrip!
        used = to_num(usedt)
        capat = td[4].text.rstrip!.lstrip!
        capa = to_num(capat) 
        ratio = (used/capa * 100 ).round 
        userurl = "usermanage?Username=" + user 
        if user != 'postmaster' then 
          p3 = agent.get(userurl) 
          p4 = p3.link_with(:text => 'メールの詳細設定').click
#        byebug 
          transaddr = p4.search('input[@name="Transfer"]').attribute('value') 
          page = p4.link_with(:text => "ユーザ管理").click  
        else 
          transaddr = "" 
        end
        address = user + '@' + dom
        if num == 0 then
          day = Time.now  
          puts "メールアドレス,転送アドレス,説明,mail,ftp, 使用量, 使用率, at #{day} " 
          file.puts "メールアドレス,転送アドレス,説明,mail,ftp, 使用量, 使用率, at #{day} " 
        end
        puts "#{address},#{transaddr},#{desc},mail:#{mail},ftp:#{ftp}, used:#{usedt}/#{capat}, ratio = #{ratio} % " 
        file.puts "#{address},#{transaddr},#{desc},#{mail},#{ftp},#{usedt}/#{capat},#{ratio}" 
        num +=1 
  
      end 

    end
  end 
end 
