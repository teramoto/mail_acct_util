# encoding: utf-8 

require 'rubygems'
require 'mechanize' 
require 'openssl'
require 'kconv'
require 'cgi'
require 'date' 

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

page = agent.get('https://lxw43009.wh3.ocn.ne.jp/cgi-bin/secure/index')
pp page 
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
fname = "tcmacct" + Date.today().to_s + ".csv" 
File.open(fname ,"w") do |file| 
  file.write $emdata.join("\n") 
end

exit

