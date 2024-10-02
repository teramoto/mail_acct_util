#!/usr/local/bin/ruby 
# encoding: utf-8 

require 'rubygems'
require 'mechanize' 
require 'openssl'
require 'kconv'
require 'cgi'

ext = Time.now.strftime("%Y%m%d")
outfile1 = "wes_arena#{ext}.csv"
outfile2 = "wes_trans#{ext}.txt" 

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
url = 'http://wes.co.jp:8080'
url2 = 'https://dc13.etius.jp/Site_Manager/?GUEST_IP=202.229.135.221' 
agent.add_auth url2, 'admin', 'Rayssu005' 
page = agent.get(url)
page2 = agent.click(page.link_with(:href => %r{/Site_Manager/} ))
# puts page2.body  
url_frame1 = 'menu.php?GUEST_IP=202.229.135.221&1=a&2='
frame1 = agent.get(url_frame1)
# p frame1.body 

#p frame1.link_with(:href => 'menu.php?GUEST_IP=202.229.135.221&amp;1=a&amp;2=a')
# p frame1.link_with(:href => "menu.php?GUEST_IP=202.229.135.221&1=a&2=a")
page2_1 = agent.click(frame1.link_with(:href => "menu.php?GUEST_IP=202.229.135.221&1=a&2=a")) 
# p page2_1 
# puts page2_1.body

  #  メールユーザの登録・変更
page_m = agent.click(page2_1.link_with(:href =>  "user_add.php?GUEST_IP=202.229.135.221&L=1-3-31-3101"))
puts page_m.body 
# File.write("useredit.txt", page_m.body)
# File.write("usrList.txt" ,page_m.at('table#usrList'))
ul = page_m.at('table#usrList')
res = ul.search('tr') 
cnt = 0
#  p res.length  

nmtx = "" 
res.each { |d| 
#  puts "-->#{d}"  
  if (cnt > 0) then 
    # p d 
    res1 = d.search('td')
    # puts res1
#    puts res1[0].inner_text 
#    puts res1[1].inner_text 
#    puts res1[2].inner_text 
    (0..3).each { |i|
      nmtx += res1[i].inner_text 
      nmtx += ','
    }
    nmtx += "\n"  
  end 
  cnt += 1  
}
File.write(outfile1, nmtx )
# puts page_m.at('table#regist')[0]
# Handling transfer address
# puts page2_1.body 

# <a href="Mtransfer.php?GUEST_IP=202.229.135.221&amp;L=1-3-31-3102" target="main"><span class="end"> メールユーザの転送設定</span></a>
paget = agent.click(page2_1.link_with(:href => "Mtransfer.php?GUEST_IP=202.229.135.221&L=1-3-31-3102"))  #  メールユーザの転送設定

# puts  paget.body 
File.write("test.txt", paget.body )
##3 process form 
transf = "" 
paget.forms.each do |f| 
#   p f 
  t1 = f.submit
  t1f = t1.forms.first  
#  p t1f
  nm = "" 
  t1f.field_with(:name => 'U_NAME') do |f1|
    nm = f1.value
  end  
  trsa = Array.new 
  (0..9).each do |n1|
    t1f.field_with( :name => "TRS#{n1}") do |f2|
      if ( f2.value.size > 0) then 
        trsa.push("  #{n1+1}:#{f2.value}") 
      end 
    end 
  end  
  if trsa.size > 0 then 
    ans =  nm + ":\n" + trsa.join("\n") + "\n" 
    puts ans
    transf += ans  
  end 
end 
File.write(outfile2, transf) 
exit
res.each do |d| 
  d.search('td').map { |res1| 
#    p res1
#    puts "tr #{res1.size}" 
#    puts "-->#{res1}<--"    
#    puts "1:#{res1[0]}:1"
    puts "res1:#{res1.text}" 
    $trn = res1.text 
#    puts "2:#{res1[1]}:2"  
  }
  p d 
  puts "form-----" 
  fm = d.at('form') 
  p fm 
#  p paget.form_with(:name=>'U_NAME')
# exit
#  res = agent.click 
 
#  ptr = paget.form_with(:name =>'U_NAME' , :value =>$trn   )  #  .submit
#  puts ptr 
exit
end
puts res.size

exit 
url_user = './menu.php?GUEST_IP=202.229.135.221&amp;1=0,4,5,6,7,3&amp;2='   #  メールユーザ管理</a>
url_useredit = 'user_add.php?GUEST_IP=202.229.135.221&amp;L=1-3-31-3101r'   #  メールユーザの登録・変更</span></a>
page3 = agent.get(url_user)
pp page3
url_user2 = "./menu.php?GUEST_IP=202.229.135.221&1=0,4,5,6,7,3&2=31"
page3 = agent.get(url_user2)
pp page3 
page4 = agent.get(url_useredit)
p page4 
puts page4.body 
exit 
ff = page.form('loginform')
ff.password = 'sbqre+gr'
ff.userid = 'tcmaxc'
pp ff 
page = agent.submit(ff)  # , ff.button.formbutton) 
pp page 
puts '------------------------'
page.links.each do |link| 
  puts "+++#{link}+++"
end
page1 =page.link_with(:text => '統計データの表示').click 
 p page1 
page1 =page.link_with(:text => 'メール設定').click
puts "title:#{page1.title}" 
pp page1 
puts page1.title 
page1.links.each do |link|
  puts "<#{link.text}:#{link.href}>" 
  if ( link.text == '設定' ) then
    res = link.href.split(/=|&/) 
#     puts res[3]  
    email = res[3].sub('%40','@') 
    puts email
    page2 = link.click
#    p page2 
    forward = page2.form['forward_to']
    pop = page2.form.checkbox_with( :name => 'pop').checked
    puts "forward:#{forward}.l:#{forward.size}" 
    puts "address:#{page2.form['address_email_last']}" 
    puts "id: #{page2.form['id_account_email']}" 
    puts "use as pop: #{pop}"   
    edata = email +"," + pop.to_s
    if  forward.size >0  then 
       edata +=  "," + forward
       f1 = forward.split(',')
       f1.each do |f| 
         forward_to.push f
       end
    end
    $addr.push email 
    $emdata.push edata 
    puts edata 
    if ( /^tc/ =~ email) then  
#      p page2 
    end 
  end
end
$addr.each do |d|
  puts d 
end
forward_to.each do |f| 
  puts f
end 

puts "#{$addr.size} address" 
puts "#{forward_to.size} forwards" 
ls = Array.new
rt = trexp('all-tc@tc-max.co.jp')
ls.concat(rt) 
begin 
  numproc = 0 
  ls.each do |e|
    if (/^tc/ =~ e) then  
      rt = trexp(e) 
      numproc += rt.size
      ls.concat(rt)
      ls.delete(e)
    end 
  end 
end until (numproc == 0 )

p ls     
p $emdata 
p $emdata.to_s 
File.open("tcmacct.csv","w") do |file| 
  file.write $emdata.join("\n") 
end

exit

