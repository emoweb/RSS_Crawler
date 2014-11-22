#!ruby -Ku

# 窓の杜
# http://www.forest.impress.co.jp/
RSS_PIPES[:forest_impress] = Proc.new{ |pipe|
  pipe.procedure_1(
    'http://www.forest.impress.co.jp/rss.xml', nil,
    '//div[@class="main-contents mainContents"]'
  ) {|h|
    # 改行,tag間の空白を除去した後に画像リンクを書き換え
    h.gsub(/[\r\n]+/, '').gsub(/\s*([<>])\s*/, '\1').
      gsub(%r!(href|src)="/!, '\1="http://www.forest.impress.co.jp/')
  }
}


