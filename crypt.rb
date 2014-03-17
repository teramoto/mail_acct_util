
require 'openssl'
require 'base64'

def encrypt(s, password)
  enc = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
  enc.encrypt
  enc.pkcs5_keyivgen(password)
  return enc.update(s) + enc.final
end
def encrypt64(s, password)
  e0 = encrypt(s, password)
  enc = Base64.encode64(e0)
  return enc 
end 

def decrypt(s, password)
  dec = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
  dec.decrypt
  dec.pkcs5_keyivgen(password)
  return dec.update(s) + dec.final
end
def decrypt64(s, password)
  d0 = Base64.decode64(s) 
  dec = decrypt(d0, password)
  return dec
end 

