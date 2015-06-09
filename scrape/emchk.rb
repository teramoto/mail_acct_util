# encoding: utf-8 

require 'rubygems'
require 'mechanize'
require 'kconv'

# if (ARGV.length < 3 ) then 
#  puts "needs login ID and password, email"
#  exit
# end
#$user = ARGV[0]
#$pass = ARGV[1] 
#$email = ARGV[2]
#dd = $email.split('@')
#$userid = dd[0]
#$domain = dd[1] 

agent =  Mechanize.new
login_page = agent.get('http://intra.ray.co.jp/cgi-bin/dneoconv/dneoconv.cgi') 

  puts login_page.body 
  links = login_page.links
  puts links.size
  links.each { |l|
    p l 
  }
  puts links[2] 
  page2 = links[2].click
## mail data convert menu ## 
  puts page2.body 
  puts page2.links 
  page_m = page2.links[1].click 
  puts page_m.body 
exit (0)
  $my_page = login_page.form_with(:name => 'form2') do  |f|
puts ('*** start ***')
  
#  my_page.fields.each { |fn| puts fn.name } 

#  f.field_with(:name => 'UserID').value  = $user
  f.UserID = $user
  f._word  = $pass
  puts f.UserID
  puts f._word
#  p form
end.click_button

p agent.page 
puts ("ログインしました。ID =#{$user}")
puts agent.page.title
  if agent.page.title != 'レイ・グループ - メール一覧' then 
     webmail = agent.get('xmail.cgi?page=maillist&log=on')
  end
  if webmail.title != 'レイ・グループ - メール一覧' then 
     webmail = agent.get('xmail.cgi?page=maillist&log=on')
  end
#  p agent.page.form_with(:name => '_form').field_with(:name =>'hsearch').value = 10 
# p agent.page.form_with(:name => '_form').field_with(:name =>'hsearch')
#  agent.page.form_with(:name => '_form').click_button 

puts webmail.title
  if webmail.title != 'レイ・グループ - メール一覧' then 
    puts webmail.title
    agent.page.each do |f| 
       puts f
    end
    p (agent.get(agent.page))
    exit
  end 
  puts ("WEBMail =#{$user}")
  acctpage = agent.get('xmail.cgi?page=mailaccounts')
  p acctpage.title 
  button = acctpage.form.button_with(:value => '新規アカウント作成')
  acctpage.form_with(:name => '_form').click_button(button) 
#  acct2 = acctpage.form_with(:name => '_form').click_button
  p agent.page.title  
  if agent.page.title != 'レイ・グループ - アカウントの登録' then 
    exit
  end
 
  p agent.page.title
  $m_form = agent.page.form_with(:name => '_form') 
  p $m_form 
  p $m_form.field_with(:name => 'account').value 
  $m_form.field_with(:name => 'userid').value = $userid + "@ray.co.jp" 
  $m_form.field_with(:name => '_word').value = $pass 
  $m_form.field_with(:name => 'mail').value = $email
  puts "#{$userid}:#{$domain}" 
  
  case $domain 
  when 'wes.co.jp'
    #  radio pop3kind = 3 
    # TODO SMTP認証をONに！ 
    # サーバーにデータを残す 
    $m_form.radiobuttons_with(:name => 'pop3kind')[2].check
    $m_form.radiobuttons_with(:name => 'smtpkind')[2].check
    $m_form.field_with(:name => 'pop3server').value = 'wes.co.jp'
    $m_form.field_with(:name => 'smtpserver').value = 'smtp.wes.co.jp'
  when 'tc-max.co.jp'
    #  radio pop3kind = 3  
    $m_form.radiobuttons_with(:name => 'pop3kind')[2].check
    $m_form.radiobuttons_with(:name => 'smtpkind')[2].check
    $m_form.field_with(:name => 'pop3server').value = 'mas14.kagoya.net'
    $m_form.field_with(:name => 'smtpserver').value = 'mas14.kagoya.net'
    $m_form.field_with(:name => 'userid').value = 'tcm.' + $userid + '@tc-max.co.jp' 
  when 'ss.ray.co.jp'
    #  radio pop3kind = 3  
    $m_form.radiobuttons_with(:name => 'pop3kind')[2].check
    $m_form.radiobuttons_with(:name => 'smtpkind')[2].check
    $m_form.radiobuttons_with(:name => 'popbsmtp')[2].check
    $m_form.field_with(:name => 'smtpauthkind').option_with( :value => '2').select
    $m_form.field_with(:name => 'pop3server').value = 'www16276uf.sakura.ne.jp'
    $m_form.field_with(:name => 'smtpserver').value = 'www16276uf.sakura.ne.jp'
    $m_form.field_with(:name => 'userid').value = $userid + '@ss.ray.co.jp' 
  end 
  $m_form.checkbox_with(:name => 'sync').check 
  p $m_form.field_with(:name => 'userid').value
  p $m_form.field_with(:name => '_word').value 
  p $m_form.field_with(:name => 'pop3server').value 
  p $m_form.field_with(:name => 'smtpserver').value 
#  page = $m_form.click_button(button) 
  agent.page.form_with(:name => '_form').submit
  p agent.page.title 
  res =  agent.page.body
  File.write("/var/www/html/foundation-4/tmp2.html" , res)

exit

  agent.page.form_with(:name => '_form').submit
  p agent.page.title
  res = agent.page.body 
  File.write("/var/www/html/foundation-4/tmp0.html" , res)
exit
p = agent.page.at("div[@class='bosyu2']") 
p p
p = agent.page.links
puts p 
exit

p = agent.page.links
puts p
p = agent.page.links
puts p
p = agent.page.class.find( "bosyu2")
# p = agent.page.links.find( |link| link.text =~ /ブンデス/ )
puts p
#p = agent.page.at(:text =>'ブンデス',:tag => 'div')
#puts p
puts 'ブンデスリーガ'.encode!('shift_jis')
puts 'ブンデスリーガ'.encode!('utf-8')
puts agent.page.link_with(:text => "Inc")
puts agent.page.link_with(:text => ("番組".tosjis))
puts agent.page.uri


