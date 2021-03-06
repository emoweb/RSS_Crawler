#!/bin/ruby -Ku
# HTTP関連の処理のまとめ

require 'net/http'
require 'uri'
require 'kconv'
require 'time'
Net::HTTP.version_1_2

module HTTPUtil
  # ブラウザごとのUserAgent
  USER_AGENT = {
    :ie10 => 'Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.2; Trident/6.0)',
  }
  
  # 標準で送るヘッダ
  DEFAULT_HAEDER_GET = {
    "User-Agent" => USER_AGENT[:ie10],
    # Accept-Encoding, Accept, Hostは勝手につけてくれる
  }
  
  
  #       header_if_modified_since(date, base_header) -> Hash
  # 
  # if-modified-sinceを使うget時のHTTPヘッダを生成する.
  # dateにDateを渡した場合はその時間,
  # Stringを渡した場合はそのファイルの更新日時を使う.
  def header_if_modified_since date, base_header = DEFAULT_HAEDER_GET.dup
    date = case date
    when String; File.mtime(date)
    when Date; date
    end
    
    base_header["If-Modified-Since"] = date.httpdate
    base_header
  end
  module_function(:header_if_modified_since)
  
  
  #       get_for_cache(url, cache_file, referer, header) -> Net::HTTPResponse
  # 
  # cacheからの変更があるか調べてDLする.
  # 変更なしの場合はcacheから読み込み,変更がある場合はcacheに書き込む
  def get_and_cache url, cache_file, referer = nil, header = DEFAULT_HAEDER_GET.dup
    cache_exists = File.exists?(cache_file)
    header = header_if_modified_since(cache_file, header) if cache_exists
    res = get(url, referer, header)
    res.body = IO.binread(cache_file) if(cache_exists && res.status == 304)
    IO.binwrite(cache_file, res.body) if((res.status / 100) == 2)
    return res
  end
  module_function(:get_and_cache)
  
  
  #       request(url, method, *arg) -> Net::HTTPResponse
  # 
  # HTTPのrequest_XXをURIパースして呼び出すためのwrapper
  def request(url, method, *args)
    u = URI(url)

    # path生成
    pt = u.path
    pt = "/" if pt.empty?
    pt += ('?' + u.query) if u.query
    pt += ('#' + u.fragment) if u.fragment
    
    c = Net::HTTP.new(u.host, u.port)
    c.use_ssl = (u.scheme == 'https')
    c.__send__(method, pt, *args)
  end
  module_function :request
  
  
  #       get(url, referer, header, redirect_max) -> Net::HTTPResponse
  # 
  # HTTPでGetする. 圧縮/解凍は勝手に処理してくれる.
  # refererがnilなら無し.
  # headerはnilなら標準.
  # status codeがredirectかつLocationが存在する場合,
  # redirect_max > 0の間,自動的にリダイレクト先に飛ぶ
  def get url, referer = nil, header = nil, redirect_max = 5
    # Header作成
    header ||= DEFAULT_HAEDER_GET.dup
    header["Referer"] = referer.to_s if referer
    
    # Request
    r = request(url, :get, header)
    
    # Redirect判定と再帰リクエスト
    if redirect_max > 0 and r.status / 100 == 3 and rdloc = r["Location"]
      r = get(rdloc, url, header, redirect_max - 1)
      r.redirect_history.push(rdloc)
    end
    
    # アクセスURLが空なら設定
    r.redirect_history ||= [url]
    
    return r
  end
  module_function :get
  
  #       post(url, data) -> Net::HTTPResponse
  # 
  # HTTPでpostする. 内容はdataに指定.
  def post url, data, header = DEFAULT_HAEDER_GET.dup
    request url, :request_post, data, header
  end
  module_function :post
  
end


# 独自の拡張メソッドをHTTP Responseに定義
class Net::HTTPResponse
  # utf8に変換したbodyを返す
  def text; body && body.toutf8; end
  
  # ステータスコードを数値型で返す.
  def status; code.to_i; end
  
  # Redirect履歴を保存するArray. lastが最終的にアクセスしたURL.
  attr_accessor :redirect_history
  
  # ResponseのURL
  def access_url
    @redirect_history.last
  end
  
end


