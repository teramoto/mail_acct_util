#!/usr/local/bin/ruby 

#
# WebArenaから取得したアカウント情報と転送リストをクロスチェック
# してOrphan アドレスを洗い出します。
#

require 'optparse'
require '../ldaputil.rb' 
require 'tracer' 
# Tracer.on

$db = false 
opt = OptionParser.new
Version = "0.1" 
opt.on('-a xxx@ray.co.jp', 'set email address') { |v| p v }
$arg = opt.parse(ARGV)

acctfile = ARGV[0]
trfile = ARGV[1] 
puts "account file: #{acctfile}" 
puts "transfer addres to chkeck: #{trfile}" 
# sleep(5)
account = Array.new
toaddr = Array.new
traddr = ""

File.foreach(acctfile) do |line|
  line.chomp! 
  # items should be split by "," 
  ll = line.split(',')
  account.push (ll[0]) 
end 
puts "#{account.size+1} address." 
# p account 
lastline = "" 
File.foreach(trfile) do |line|
  line.chomp!
  if /^\s\s/ =~ line then 
    puts "addr to trans #{line}" if $deb
    if /^\s\s[0-9]*:/ =~ line then 
      puts $' if $deb 
      wadr = $'
      xadr = wadr.split('@') 
      if xadr != nil then
        case xadr[1] 
        when 'wes.co.jp' 
          if account.index(xadr[0]) == nil then 
            puts "#{xadr[0]} not found! #{lastline}"
          end 
        when 'ray.co.jp' 
        else 
        end 
      else 
        puts "line error #{wadr}" 
      end 
    else 
      puts "line error.#{line}" 
    end
  else 
    lastline = line 
  end
end 
