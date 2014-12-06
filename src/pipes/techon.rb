#!ruby -Ku

# 日経テクノロジーオンライン
# http://techon.nikkeibp.co.jp/
# Loginが必要

RSS_PIPES[:techon] = Proc.new{ |pipe|
  opt = {
    :feed => 'http://techon.nikkeibp.co.jp/rss/index.rdf',
    :fetch => {
      :replace => [
        /[\r\n]/, [/\s*([<>])\s*/, '\1'],
        [%r#^.*?(<div id="kiji">.*?)<!-- /.pagingBox -->.*$#, '\1'],
        [/(<\w+)\sclass=\"[^\"]+">/, '\1>'],
      ],
      :abslink => true,
    }    
  }
  pipe.pipe_procedure(opt)
  
}

