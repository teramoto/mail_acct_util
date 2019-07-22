#!/usr/local/bin/ruby 
require 'cgi' 

def cgi_header(cgi, title)
        cgi.meta("charset" => "utf-8" ) { } +  
        cgi.meta("name" => "viewport","content" =>"width-device-width" ) { } + 
        cgi.title { title }  + 
        "<link rel=\"stylesheet\" href=\"/css/normalize.css\" />" +
        "<link rel=\"stylesheet\" href=\"/css/foundation.css\" />" +
#        cgi.link( :rel=> "stylesheet", :href => "css/normalize.css") { } + 
#        cgi.link( :rel=> "stylesheet", :href => "css/foundation.css" ) { } +
#         "<SCRIPT src=\"js/vender/custom.modernizr.jS\"></SCRIPT>"
#        cgi.script(:src => "js/vendor/custom.modernizr.js") { }   
        "<script src=\"/js/vendor/custom.modernizr.js\"></script>"    
end

def cgi_footer(cgi)
    "<script>" +
    "document.write('<script src=' + " +
    "('__proto__' in {} ? '/js/vendor/zepto' : '/js/vendor/jquery') + " + 
    "'.js></script>')" +
    "</script>" +

  "<script src =\"js/foundation.min.js\"></script>" + 
  "<!-- " + 
  "<script src=\"/ja/foundation/foundation.js\"></script>" +
  "<script src=\"/ja/foundation/foundation.alerts.js\"></script>" +
  "<script src=\"/ja/foundation/foundation.clearing.js\"></script>" +
  "<script src=\"/ja/foundation/foundation.cookie.js\"></script>" +
  "<script src=\"/ja/foundation/foundation.dropdown.js\"></script>" +
  "<script src=\"/ja/foundation/foundation.forms.js\"></script>" +
  "<script src=\"/ja/foundation/foundation.joyride.js\"></script>" +
  "<script src=\"/ja/foundation/foundation.magellan.js\"></script>" +
  "<script src=\"/ja/foundation/foundation.orbit.js\"></script>" +
  "<script src=\"/ja/foundation/foundation.placeholder.js\"></script>" +
  "<script src=\"/ja/foundation/foundation.reveal.js\"></script>" +
  "<script src=\"/ja/foundation/foundation.section.js\"></script>" +
  "<script src=\"/ja/foundation/foundation.tooltips.js\"></script>" +
  "<script src=\"/ja/foundation/foundation.topbar.js\"></script>" +
  "-->" +
  cgi.script() {
    "$(document).foundation();"
  }
end 


