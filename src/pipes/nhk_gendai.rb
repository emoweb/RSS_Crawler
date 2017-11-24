#!ruby -Ku

# NHK　クローズアップ現代
# http://www.nhk.or.jp/gendai/archives/
# 全文配信をRSSに加工する.
# かなり特異な構造のため,pipeはxmlの保存,Log出力等のみに使用する.

require 'rss'
require 'nokogiri'
require 'uri'

NHK_GENDAI_ROOT_PAGE = 'http://www.nhk.or.jp/gendai/archives/'

RSS_PIPES[:nhk_gendai] = proc{ |pipe|
  # :feed作成処理 -----------
  
  # 最新のページURLを取得
  idxpage = Nokogiri::HTML(pipe.page_access(NHK_GENDAI_ROOT_PAGE).text)
  # 取得したarchiveの月を取得. RSSの時間設定に利用
  cal_month = idxpage.xpath('string(//*[@class="calendar__title"])').gsub(/月|日/, '/')

  # 項目を取得しitemを生成
  pipe.dl_items = []
  idxpage.xpath('//div[@class="calendarItem"]').each{ |nd|
    # ダイジェストが存在するか確認
    next if nd.xpath('.//span[@class="label--digest"]').empty?
    # アイテム生成と追加
    r = RSS::Rss::Channel::Item.new()
    pipe.dl_items << r
    # link取得, 設定
    r.link = (URI(NHK_GENDAI_ROOT_PAGE) + nd.xpath('string(./a/@href)')).to_s
    # 時間取得し設定. 放送時間に合わせ公開日の22:00にする.
    cal_day = nd.xpath('string(.//*[@class="dateText"])')
    r.date = Time.parse(cal_month + cal_day + " 22:00")
  }

  # channelを設定
  pipe.channel.merge!({
    :title => "NHK クローズアップ現代",
    :description => "クローズアップ現代の全文配信",
    :link => NHK_GENDAI_ROOT_PAGE,
    :about => NHK_GENDAI_ROOT_PAGE
  })

  # feed作成後は普通のpipe_procedure
  # filterは不要
  # 前回分読み出し
  pipe.read_saved()
  # fetch
  pipe.fetch(
    :xpath => '//div[@class="column__main"]',
    :remxpath => [
      './/div[@class="article__meta"]',
      './/div[@class="article__footer"]'
    ],
    :abslink => true,
    :get_title => true,
  )
  # 出力
  pipe.save_rss
}
