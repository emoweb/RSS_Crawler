#!ruby -Ku

# Tech総研
# http://next.rikunabi.com/tech/index.rdf
# RDFに細工をしないとパースできない

RSS_PIPES[:rikunabi_tech] = Proc.new{ |pipe|
  # RDFを取得して編集
  pipe.info{'access RDF'}
  rssbin = HTTPUtil::get('http://next.rikunabi.com/tech/index.rdf').body
  rssbin.gsub!('        <rdf:li rdf:resource=""/>' + "\n", '')
  rssbin.gsub!(<<EMPTYITEM, '')
  <item rdf:about="">
    <title> </title>
    <link></link>
    <dc:date></dc:date>
    <description></description>
  </item>
EMPTYITEM
  rssio = StringIO.new(rssbin, 'r')
  
  # 処理引数を指定しfetch
  opt = {
    :feed => rssio,
    :fetch => {
      :xpath => '//div[@class="report_con"]',
      :replace => [
        /[\r\n]/,
        [/<(div|p|span)\s((class|style|name|id)=\"[^\"]*\"\s*)*>/, '<\1>'],
      ],
      :abslink => true,
    }
  }
  pipe.pipe_procedure(opt)
}

