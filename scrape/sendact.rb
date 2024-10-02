require 'byebug'
require 'logger'

$logger = Logger.new('account_info.log')

File.open('conoha_mail.csv') do |file|
  file.each_line do |line|
    aa = line.split(',')
    puts aa[0]
    com = "\./actchkl3.rb -r -e -z -h 新メールサーバーの設置情報をお送りします。 #{aa[0]}" 
    puts com 
    res = `#{com}` 
    puts res.class
    puts "#{res.length},#{res}" 
    byebug if $deb
    $logger.info("#{aa[0]},#{$res}") 
    if res.length ==0  then 
#    if res > 0 then 
      exit 0
    end 
  end
end

