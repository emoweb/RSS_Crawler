#!/bin/ruby -Ku

# 
# https://comic-meteor.jp/information/
# HTMLのみ提供

COMICMETEOR_TITLE = "COMICメテオ>最新情報"
COMICMETEOR_INFO_PAGE = 'https://comic-meteor.jp/information/'

RSS_PIPES[:comic_meteor] = Proc.new{ |pipe|
  # 項目を取得しitemを生成 -----------------
  node = Nokogiri::HTML(pipe.page_access(COMICMETEOR_INFO_PAGE).text)
  pipe.dl_items = []
  node.xpath('id("infomation_wrap")/ul').each{ |nd|
    # アイテム生成と追加
    r = RSS::Rss::Channel::Item.new()
    pipe.dl_items << r
    # link取得と設定. 絶対パス指定のため不要だが念の為相対リンクでもパースできるように.
    r.link = (URI(COMICMETEOR_INFO_PAGE) + nd.xpath('string(li/a/@href)')).to_s
    # 日付を取得し設定. 日付のみなので時間は0:00になる.
    r.date = Time.parse(nd.xpath('string(li[@class="date"])'))
    # タイトルはfetchで取得するため設定しない
  }

  # channelを設定 --------------------------
  pipe.channel.merge!({
    :title => COMICMETEOR_TITLE,
    :description => COMICMETEOR_TITLE,
    :link => COMICMETEOR_INFO_PAGE,
    :about => COMICMETEOR_INFO_PAGE
  })

  # fetch -----------------------------------
  pipe.read_saved()
  pipe.fetch(
    :xpath => '//div[contains(@class,"info_contents")]',
    :remxpath => [
      './/div[contains(@class,"history_inner")]',
      './/p[@class="social"]'
    ],
    :abslink => true,
    :get_title => true,
  )
  pipe.save_rss() # 出力

}
