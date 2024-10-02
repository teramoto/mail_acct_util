#!/usr/local/bin/ruby

def password_gen(size=8)
  pass = [*0..9, *'a'..'z', *'A'..'Z'].sample(size).join
  if /[0-9]/ =~ pass then
    if /[a-z]/ =~ pass then 
      if /[A-Z]/ =~ pass then 
        return pass
      end 
    end 
  end
end

def mkps8 
  ps = "" 
  until ps != nil && ps.length == 8 
    ps = password_gen(8)
#    puts ps 
  end 
  return ps 
end 
