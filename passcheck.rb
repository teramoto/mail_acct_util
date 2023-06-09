require './popchecks' 
require './ldaputil' 
require 'byebug' 
require 'sqlite3' 
require 'csv' 


csvfile = "mails.csv" 
outfile = "mpass.csv" 
$of = File.open(outfile,"w")
puts $of

# mcsv = CSV.new(mfile) 

# $db = SQLite3::Database.new("/home/rails/RalisReact/db/development.sqlite3") 
$db = SQLite3::Database.new("development.sqlite3") 
$db2 = SQLite3::Database.new("developmentk.sqlite3") 
res = $db.execute("SELECT * from people" )
p res 

user = "nakagami@ray.co.jp" 
user = "ken@ray.co.jp" 
email = user 
passwd = "Kentar00" 
# byebug 
def setpass(email,passwd)
  uid = email
  dn = "uid=#{uid},ou=Mail,dc=ray,dc=co,dc=jp"
  attr = "userpassword" 
  value = passwd
  ldaphost = "ldap.ray.co.jp" 
  stat = ldaprplattr(dn, uid, attr, value, ldaphost ) 
end 

def pwcheck(email ) 
  server = "mail.ray.co.jp" 
  comm = "r" 
  passwd = getpass(email) 
  puts passwd 
  if passwd.size > 2 then 
    ret = popcheck(email, server, passwd, comm )
    if ret == false  then 
      puts "User:pass is OK. #{email}:#{passwd}:ldap" 
      $of.puts "#{email},#{passwd}" 
      return passwd 
    else 
      puts "invalid passwd. Continue to SQL"
    end 
  end
  sql = "SELECT password from PEOPLE WHERE mail=\'#{email}\'"
  # byebug
  pws = $db.execute(sql)
  puts pws 
  pws1 = pws.uniq 
  pws1.each do |ps|
    ps1 = ps.uniq 
    ps1.each do |pp|
      puts "#{email}::#{pp}" 
      ret = popcheck(email,server, pp, comm) 
      if ret == false  then 
        puts "User:pass is OK. #{email}:#{passwd}:SQL" 
        $of.puts "#{email},#{passwd}" 
        return passwd 
      else 
        puts "invalid passwd.Contine to next sql"
        # return nil 
      end 
    end 
  end

  pws = $db2.execute(sql)
  puts pws 
  pws1 = pws.uniq 
  pws1.each do |ps|
    ps1 = ps.uniq 
    ps1.each do |pp|
      puts "#{email}::#{pp}" 
      ret = popcheck(email,server, pp, comm) 
      if ret == false  then 
        puts "User:pass is OK. #{email}:#{passwd}:SQL" 
        $of.puts "#{email},#{passwd}" 
        return passwd 
      else 
        puts "invalid passwd.Contine to next sql"
        # return nil 
      end 
    end 
  end


  puts "No Passwod found.#{email}" 
  $of.puts "#{email},XXXXXXXX" 
  return nil  
end 

popinit 
$deb = false 
CSV.foreach(csvfile){ |row|
  p row[0]
  if ((row[0] != nil) && (row[0].size > 0))  then 
    pwcheck(row[0]) 
  end
}
if false then 
  email = "ken@ray.co.jp" 
  pw = "Kentar00" 
  puts pwcheck( email)
  puts pwcheck("nakagami@ray.co.jp") 
end

$of.close  
