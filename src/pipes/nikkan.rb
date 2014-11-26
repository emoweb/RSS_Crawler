#!ruby -Ku

# 日刊工業新聞 Business Line　新着ニュース
# http://www.nikkan.co.jp/rss/nksrdf.rdf

# RDFに細工をしないとパースできない
#require __FILE__ +

RSS_PIPES[:nikkan] = Proc.new{ |pipe|
  # RDFを取得して編集
  pipe.info{'access RDF'}
  rssbin = HTTPUtil::get('http://www.nikkan.co.jp/rss/nksrdf.rdf').body
  rssbin.sub!('</dc:date>', "</dc:date>\n<description> </description>\n")
  rssio = StringIO.new(rssbin, 'r')
  
  # パース
  pipe.procedure_1(rssio, nil, nil) {|h|
    # 改行,tag間の空白を除去した後に本文抽出
    h = h.gsub(/[\r\n]+/, '').gsub(/\s*([<>])\s*/, '\1')
    h =~ /<!-- ■抄録文■ -->(.*)<!-- e-nikkan -->/
    h = $1
    # タグを書き換え
    h = h.gsub(%r!(href|src)="!, '\1="http://www.nikkan.co.jp/news/')
    
    h # .tap{|r| IO.write("Z:/#{Time.now.to_i}.html", r) }
  }
}

