#!ruby -Ku

# 絶対リンクへの変換テスト

require 'kconv'
require 'uri'

html = IO.read('z:/1.html').toutf8
base = URI.parse('http://www.excite.co.jp/News/bit/E1416812433353.html')
r = html.gsub(/\s(href|src)=\"([^\"]+)\"/){|mt|
  p mt
  %Q! #{$1}="#{base.merge($2)}"!
}.gsub(/[\r\n]/, '')
puts r

