#!/usr/local/bin/ruby 
# encoding : utf-8 
#

require './ldaputil.rb'

# account information from OCN via scraping.. 
  File.open('./scrape/tcmacct.csv', 'r') do |file| 
    p file 
    file.each do |line|
      puts line
    end
  end

  File.open('./scrape/TCMail1.csv','r') do |file|
    file.each do |line|
     if line.length > 6 then 
        pp = line.split(',')
        p pp 
        passwd = pp[0]
        mail = pp[1] 
        uid = mail
        domain = 'tc-max.co.jp'
        pp1 = mail.split('@')
        sei = pp1[0]
        mei = pp1[1]
        puts ("uid:#{uid},mail:#{sei},pass:#{passwd},sei:#{sei},mei:#{mei},domain:#{domain}")
        ldapout(uid, sei, passwd,sei,mei,domain,sei,mei, 99999 )
      else 
        puts ("skipped #{line}")
      end 
    end
  end 



# def ldapout(uid, mail, passwd, sei, mei, domain)

