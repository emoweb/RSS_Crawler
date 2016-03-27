#!/bin/ruby -Ku

# NHKニュース
# http://www3.nhk.or.jp/news/
# 
# JUST IN :nhknews-live
# "http://www3.nhk.or.jp/rss/news/cat-live.xml"
# 主要ニュース :nhknews0
# "http://www3.nhk.or.jp/rss/news/cat0.xml"
# 社会 :nhknews1
# "http://www3.nhk.or.jp/rss/news/cat1.xml"
# 文化・エンタメ :nhknews2
# "http://www3.nhk.or.jp/rss/news/cat2.xml"
# 科学・医療 :nhknews3
# "http://www3.nhk.or.jp/rss/news/cat3.xml"
# 政治 :nhknews4
# "http://www3.nhk.or.jp/rss/news/cat4.xml"
# 経済 :nhknews5
# "http://www3.nhk.or.jp/rss/news/cat5.xml"
# 国際 :nhknews6
# "http://www3.nhk.or.jp/rss/news/cat6.xml"
# スポーツ :nhknews7
# "http://www3.nhk.or.jp/rss/news/cat7.xml"

# require 'base62'
require 'cgi'

# twitterの検索リンクを追加するためだけに独自のProcを作っている.
# link情報が必要なため,edit_procでは対応できない.
# ただし追加する部分以外は標準fetch.


module NHKNews
  
  # NHK特有の短縮URLを生成
  # def make_short_url url
  #   url =~ /^http:\/\/www3?\.nhk\.or\.jp\/news\/html\/(\d{8})\/[tk](\d{3})(\d{7})(\d)\d{3}\.html$/
  #   d = $1
  #   id = $3.to_i
  #   d =~ /^(\d\d\d\d)[-]?(\d\d)[-]?(\d\d)$/
  #   ud = Time.utc($1.to_i, $2.to_i, $3.to_i).to_i / 86400
  #   return "http://nhk.jp/N" + ud.base62_encode + id.base62_encode
  # end
  # module_function :make_short_url
  
  # twitter検索リンク生成
  def twitter_search_link baseurl
    # shorturl = make_short_url(baseurl)
    # q = CGI.escape(shorturl + " OR " + baseurl)
    q = CGI.escape(baseurl)
    surl = "https://twitter.com/search?q=#{q}"
    return "<a href=\"#{surl}\">twitter search</a>"
  end
  module_function :twitter_search_link
  
  # fetch options
  FETCH_OPT = {
    :xpath => '//article[@class="module module--detail"]',
    :replace => [
      [/<div id=\"news_video\">[^<]+<\/div>/, ''], # Flashでの動画再生用リンク
      /^\s+/, /[\r\n]/, # 空白・改行
      [/<(div|p|ul|li|span)\s((class|id|style)=\"[^\"]*\"\s*)*>/, '<\1>'], # class情報
#      /^.*?-->/,
      /<!--.*?-->/, # HTML先頭とコメント
#      [%r!<h\d[^>]*>(.*?)</h\d>!, '\1'], # h→b
#      [%r!<div>関連ニュース<ul></ul></div><div><span>[\w\.]+</span>!, '<br /><div>'],
#      %r!<div><div><ul>.*?</ul></div></div>$!, # 最後のリンクとか
#      [%r!<(/)?span>!, '<\1b>'], # span→b
#      '<div>関連ニュース[自動検索]<ul></ul></div>', # 関連Newsなし
#      '<div>関連リンク<ul></ul></div>', # 関連リンクなし
#      %r!^<div><div><a [^>]*>.*?ニュース</a></div></div>!,
    ],
    :remxpath => [
      '//script'
    ],
    :abslink => true,
  }
  
  # fetchの実行
  def fetch pipe, item
    return nil unless r = pipe.get_description(item,FETCH_OPT)
    # 無駄なdivを削除. 削除後に発生した分も消せるようにする
#    rtmp = r
#    r = rtmp while (rtmp = r.gsub('<div></div>', '')) != r
    # twitterリンクを付けて返す
    return r + twitter_search_link(item.link)
  end
  module_function :fetch
  
end

["-live", *(0..7).to_a].each{|catname|
  name = "nhknews#{catname}".to_sym
  RSS_PIPES[name] = Proc.new{ |pipe|
    opt = {
      :feed => "http://www3.nhk.or.jp/rss/news/cat#{catname}.xml",
      :fetch => Proc.new{ |item|
        NHKNews.fetch(pipe,item)
      }
    }
    pipe.pipe_procedure(opt)
  }
}




