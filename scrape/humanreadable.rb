require 'byebug' 

##
#  Humanreadable.rn 
#  generate humanreadable numbers
#
##

class Object
  def included? *params
    params.each do |param|
      return true if param === self 
    end
    false
  end
end

def as_size(s)
#  units = %W(B KiB MiB GiB TiB)
  units = %W(B KB MB GB TB)

  size, unit = units.reduce(s.to_f) do |(fsize, _), utype|
    fsize > 512 ? [fsize / 1024, utype] : (break [fsize, utype])
  end

  "#{size > 9 || size.modulo(1) < 0.1 ? '%d' : '%.1f'} %s" % [size, unit]
end

def to_num(s)
  units = %W(B KB MB GB TB) 
  s1 = s.upcase
  if /[KMGT]*[B]/ =~ s1 then 
  #  byebug 
    case $&  
    when 'B' then 
      mul = 1 
    when 'KB' then 
      mul = 10 
    when 'MB' then 
      mul = 20 
    when 'GB' then 
      mul = 30 
    when 'TB' then 
      mul = 40 
    else 
      mul = 1 
    end 
  #  puts $` 
    val = $`.to_f * ( 2 ** mul) 
    return val  
  end 
  return s1.to_f
end 
  
# puts as_size(ARGV[0])
# puts to_num(ARGV[0])

