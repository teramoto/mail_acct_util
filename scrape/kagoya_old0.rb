# encoding: utf-8 

require 'rubygems'
require 'mechanize' 
require 'openssl'
require 'kconv'
require 'cgi'
require 'date' 
require 'mail'
require 'nkf' 

# $deb = true 
$addr = Array.new 
$emdata = Array.new
forward_to =  Array.new 
I_KNOW_THAT_OPENSSL_VERIFY_PEER_EQUALS_VERIFY_NONE_IS_WRONG = nil
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
puts Mechanize::VERSION
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

puts agent.ca_file
# puts agent.cert
# puts agent.key
puts agent.pass
puts agent.verify_callback

page = agent.get('https://cp.kagoya.net')
#    <td class='right'>アカウント名:</td>
#    <td class='left'><input type='text' name='b[login][name]' value='' style='width:160px;'></td>
#    <td class='right'>パスワード:</td>
#    <td class='left'><input type='password' name='b[login][passwd]' value='' style='width:160px;'></td>

# pp page 
# ff = page.forms.first()
# ff = page.forms[0]
ff = page.forms[1]
# puts "-" * 100 
#pp ff 
# exit

#ff.fields.each { |f| 
#  if (f.type == 'INPUT' ) then 
#    puts f.name
#  else 
#    puts f.type 
#  end  
#} 
# set ID and password 
ff.field_with(:name => 'b[login][name]').value = 'tcm' 
ff.field_with(:name => 'b[login][passwd]').value = 'Ray12345' 

page = ff.submit() 
# pp page
# puts "1" * 100 
p2 = page.link_with( :href => '?a%5Bmid%5D%5Bmain%5D=mail' ).click  
#p p2 
#p2.links.each do |l| 
#  p l
#end 
p3 = p2.links[15].click
# pp p3
File.write('maillist.html', p3.body ) if $deb 
# mail index 

tt = p3.search('table.sortable') 
# puts "2" * 100
File.write('table_s.txt', tt) if $deb
# p tt 
##tr = tt.search('tr') 
##puts "tr" * 50 
# p tr 
ln= 1 
mn = 0
tdn = 0  
##tt.xpath('//tr/td[@class="def_"').each do |t| 
# [@*[contains(., 'session')]]
addr = ""
address = ""  
comment = "" 
capa = -99
used = -99 

# fromaddr, Array toaddr , Array ccaddr ,  Array body 
$adminaddr = [ "niijima@tc-max.co.jp", "tarukawa@tc-max.co.jp", "ken@ray.co.jp"  ]
$dbuser = [ "ken@ray.co.jp" ] 
def send_mail(fromaddr,toaddr, ccaddr , subject, body) 
  mail = Mail.new
  mail.charset = 'ISO-2022-JP' 
  mail.from = fromaddr 
  if $deb then # for test 
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
body= <<EOS
#{address}のメールボックスは現在#{ratio}% が使用されています。(総容量#{capa}MB中使用容量#{used}MB) 
80% を超えますと大きいメールが受信できなくなる等のトラブルが発生しますので、
メールサーバーの該当メールボックス内の不要なメールの削除をお願い致します。
削除はメーラーの設定、Webメールから行うことができます。
Webメールのアドレス：https://activemail.kagoya.com/
ユーザーID:#{acct}
パスワード:メールのパスワード

EOS

#  $deb = true 
  send_mail('noreply@ray.co.jp',Array[address], Array['networkteam@ray.co.jp']  , 'メール残容量にご注意ください', body)

#  p body 
end 

tt.xpath('//tr/td[@class[starts-with( ., "def_")]]').each do |t| 
#    puts "." * 100 
#  p t.keys
#  p t 
#  puts t 
  case t['class'] 
  when 'def_left'
    if t['style'] == nil then  
#      puts "def_left" 
      addr = t.xpath('.//a').text
      capa = -1 
      used = -1 
      comment = "" 
      if /^tcm\./ =~ addr then 
        address = $' + "@tc-max\.co\.jp" 
      end 
      ln += 1
#      puts t 
    end 
  when 'def_right' 
    if t['style'] == nil then 
#      puts "def_right" 
      comment = t.text 
      ln += 1
#      puts t 
    end 
  when 'def_right_r' 
    if t['style'] == nil then 
#      puts "def_right_r" 
      if /[0-9,]*MB/ =~ t.text then 
        v1 = $&.gsub(',','') 
        val = v1.to_i 
#        p v1, val 
        if capa < 0 then 
           capa = val 
        elsif used < 0 then 
           mn += 1 # t.length 
           used = val
           ratio = used.to_f * 100.00 / capa.to_f 
           rr1 = sprintf("%0.2f", ratio)
           puts "#{mn}:#{address},#{used}/#{capa} #{rr1}%  #{comment} " 
           if ratio >= 70.0 then
#           if address == 'jinmura@tc-max.co.jp' then 
#              puts "#{capa};#{used}" 
#              p t.text 
#              exit
#           end  
#           if address == 'ken@tc-max.co.jp' then 
             warnuser(address, addr, rr1 , used, capa , comment) 
           end 
           address = addr = comment = ""
           capa = userd = -99
        end 
      end 
      ln += 1
#      puts t 
    end 
  else 
  end 
#  puts "#{ln}:#{n}:#{t.body}"   
#  if ln > 10 then 
#    td.each do |tmp|
#      puts tmp.xml.inner_txt
#    end
#  else
#    puts "X" * 100 
#  end   
#  puts ti
#  ln += 1 
end 

