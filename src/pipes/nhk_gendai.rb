#!ruby -Ku

# NHK　クローズアップ現代
# http://www.nhk.or.jp/gendai/kiroku/
# 全文配信をRSSに加工する.
# かなり特異な構造のため,pipeはxmlの保存,Log出力等のみに使用する.

require 'rss'

NHK_GENDAI_MAX_PAGE = 5

RSS_PIPES[:nhk_gendai] = proc{ |pipe|
  # 最新のページURLを取得
  idxpage = pipe.page_access('http://www.nhk.or.jp/gendai/kiroku/')
  %r!<a href="detail_(\d+)\.html">! =~ idxpage.text
  maxidx = $1.to_i
  
  # get feed に相当. 適当にitemを生成し突っ込む
  pipe.dl_items = (0...NHK_GENDAI_MAX_PAGE).collect{|i|
    RSS::Rss::Channel::Item.new.tap{ |itm|
      itm.link = "http://www.nhk.or.jp/gendai/kiroku/detail02_#{maxidx - i}_all.html"
      itm.date = Time.now
    }
  }
  
  # 前回の保存分を読み出す.
  # 同じ項目が存在する場合,前のstepで生成した項目は上書きされる.
  # dateはTime.nowのため,重複検出はlinkを用いる.
  prev = pipe.read_saved(proc{|i| i.link })
  
  # channelを設定
  pipe.channel.merge!({
      :title => "NHK クローズアップ現代",
      :description => "クローズアップ現代の全文配信",
      :link => 'http://www.nhk.or.jp/gendai/kiroku/',
      :about => 'http://www.nhk.or.jp/gendai/kiroku/'
  })
  
  # fetch & save
  opt = {
    :xpath => '//div[@class="section01"]',
    :replace => [
      /[\r\n]/,
      [/(<\w+)\sclass=\"[^\"]+">/, '\1>'],
      [/\s*([<>])\s*/, '\1']
    ],
    :abslink => true,
    :get_title => proc{|t| t.sub(/ - NHK.*$/,'') }
  }
  pipe.fetch(opt)
  pipe.save_rss
}
