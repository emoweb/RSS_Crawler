#!ruby -Ku

# ITPro

# RDFに細工をしないとパースできない
#require __FILE__ +

RSS_PIPES[:itpro] = Proc.new{ |pipe|
  # RDFを取得して編集
  pipe.info{'access RDF'}
  rssbin = HTTPUtil::get('http://itpro.nikkeibp.co.jp/rss/ITpro.rdf').body
  
  subptn = <<PTN
<item rdf:about="">
<title></title>
<link></link>
<description></description>
<dc:date></dc:date>
</item>
PTN
  rssbin.gsub!(subptn, '')
  rssbin.gsub!('<rdf:li rdf:resource="" />' + "\n", '')
  rssio = StringIO.new(rssbin, 'r')
  
  # 処理引数を指定しfetch
  opt = {
    :feed => rssio,
    :filter => '^［PR］',
    :fetch => {
      :xpath => '//div[@id="kiji"]',
      :replace => [
        [%r'("[^"]+)&amp;([^"]+")', '\1&\2'],
        [%r'<div\s((class|style|id)=\"[^\"]*\"\s*)*>', '<div>']
      ],
      :abslink => true,
    }
  }
  pipe.pipe_procedure(opt)
}
  