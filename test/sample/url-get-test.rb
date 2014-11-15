#!ruby -Ku

# リダイレクトのあるURLの処理テスト


LIBDIR = File.join(File.expand_path(__FILE__), '../../src/lib/')
require File.join(LIBDIR, 'httputil')

u = 'http://rss.rssad.jp/rss/artclk/B3DXScOKRO4i/4caff1dc1516bfd03774672774f40ba7?ul=kDaYlq2Am5xosibAPsk2TifAueU7zxt8rgcwNECV3C4s6qJNErxg7fr8BeVlFms.Ui.q2hlbv8onI6z0CEvtjvVIhi3n'
#r = HTTPUtil.get(u, nil, nil, 0)
#r.canonical_each{|k,v| p k,v}
#p r["Location"]
r = HTTPUtil.get(u)
#IO.write("z:/out.html", r.body)

require 'nokogiri'

n = Nokogiri::HTML r.body
n2 = n.xpath '//div[@class="story"]'
IO.write("z:/out.html", n2.to_s)



