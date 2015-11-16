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
  
  # 処理引数を指定しfetch
  opt = {
    :feed => rssio,
    :fetch => {
      :replace => [
        /[\r\n]/, [/\s*([<>])\s*/, '\1'],
        [/^.*<!-- ■抄録文■ -->(.*)<!-- e-nikkan -->.*$/, '\1']
      ],
      :abslink => true,
    }
  }
  pipe.pipe_procedure(opt)
}

