#!/user/bin/ruby

require 'mail' 
require 'logger' 
require 'byebug' 
require 'sqlite3' 

$deb = true
$num = 1 

def mail_read( user, pass )
  outfile = File.open($fn + '.mbox', 'w+')

  server = "mail01.bizmail2.com" 
  
  Mail.defaults do
    retriever_method :pop3, :address    => server, 
                          :port       => 995,
                          :user_name  => user,
                          :password   => pass,
                          :enable_ssl => true
  end
  # mbox = MBOX.new
  
  emails = Mail.find(:what => :last, :count => 100, :order => :desc)
  puts emails.length #=> 10
  emails.each do |m| 
    dt = m.date
    fr = m.from 
    to = m.to
    sub = m.subject 
    puts "#{$num}:#{dt}:#{fr},#{to}.#{sub}" 
    $num +=1
    dts = dt.to_s 
    outfile.puts "From - #{dts}" 
    outfile.puts "#{m}\r\n\r\n" 
    byebug if $deb
  end
  outfile.close
end 

user = ARGV[0] 
pass = ARGV[1] 

puts( "user=#{user}, pass=#{pass}")
$fn = user.gsub('@', '_') 	
begin 
  $db = SQLite3::Database.new($fn + '.db')
  byebug
rescue => e
  puts e 
end 
mail_read( user, pass) 

