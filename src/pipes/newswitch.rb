#!/bin/ruby -Ku

# ニュースイッチ Newswitch by 日刊工業新聞社
# https://newswitch.jp/
# トピックスページから記事リストを読み出し全て全文配信化する

require 'rss'
require 'nokogiri'
require 'uri'

NEWSWITCH_TITLE = 'ニュースイッチ'
NEWSWITCH_TOPICS_URL = 'https://newswitch.jp/'


RSS_PIPES[:newswitch] = proc{ |pipe|
  # 項目を取得しitemを生成 -----------------
  node = Nokogiri::HTML pipe.page_access(NEWSWITCH_TOPICS_URL).text
  pipe.dl_items = []
  topics = node.xpath('//article[@class="list_news"]')
  pipe.info { "hit #{topics.size} topics" }
  topics.each do |tpnd|
    # アイテム生成と追加
    r = RSS::Rss::Channel::Item.new()
    pipe.dl_items << r
    # link取得と設定. linkは親nodeしか持たないのでdata-aidから生成
    aid = "./p/#{tpnd.xpath('string(./*/@data-aid)')}"
    r.link = (URI(NEWSWITCH_TOPICS_URL) + aid).to_s
    # 日付を取得し設定
    r.date = Time.parse(tpnd.xpath('string(./meta/@content)'))
    # タイトルはfetchで取得するため設定しない
  end
  
  # channelを設定 --------------------------
  pipe.channel.merge!({
    :title => NEWSWITCH_TITLE,
    :description => NEWSWITCH_TITLE,
    :link => NEWSWITCH_TOPICS_URL,
    :about => NEWSWITCH_TOPICS_URL
  })

  # fetch -----------------------------------
  pipe.read_saved()
  pipe.fetch(
    :xpath => '//div[contains(@class,"article_text")]',
    # :remxpath => [],
    # :abslink => true,
    :get_title => true,
  )
  pipe.save_rss() # 出力

}


