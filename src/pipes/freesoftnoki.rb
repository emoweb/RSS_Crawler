#!ruby -Ku

# フリーソフトの樹
# http://freesoftnoki.blog87.fc2.com/
RSS_PIPES[:freesoftnoki] = Proc.new{ |pipe|
  pipe.procedure_1(
    'http://feedproxy.google.com/frnoki', nil,
    '//td[@class="main_txt"]'
  ) {|h|
    # 改行,tag間の空白を除去した後に余分なfooterも削除
    h.gsub(/[\r\n]+/, '').gsub(/\s*([<>])\s*/, '\1').
      sub(%r!<div align=\"left\">.*(</td>)!, '\1')
    #  tap{|r| IO.write("Z:/#{Time.now.to_i}.html", r) }
  }
}

