#!ruby -Ku

# 2ch等のまとめblog

# 痛いニュース(ﾉ∀`)
# http://blog.livedoor.jp/dqnplus/
RSS_PIPES[:dqnplus] = Proc.new{ |pipe|
  pipe.procedure_1(
    'http://blog.livedoor.jp/dqnplus/index.rdf',
    nil,
    '//div[@class="blogbody"]'
  ) {|h|
    h.gsub!(/[\r\n]+/, '')
    h =~ %r#<\!-- google_ad_section_start -->(.*?)<div class="posted"></div>#
    $1
  }
}


