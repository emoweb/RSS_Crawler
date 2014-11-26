#!ruby -Ku
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
  def request url, method, *arg
    u = URI url
    pt = u.path
    pt = "/" if pt.empty?
    pt += ('?' + u.query) if u.query
    pt += ('#' + u.fragment) if u.fragment
    Net::HTTP.new(u.host, u.port).__send__(method, pt, *arg)
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
    header ||= DEFAULT_HAEDER_GET.dup
    #p [url,referer,header]
    header["Referer"] = referer.to_s if referer
    r = request(url, :get, header)
    if redirect_max > 0 and r.status / 100 == 3 and r["Location"]
      r = get(r["Location"], url, header, redirect_max - 1)
    end
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
  # Content-Typeに対応する拡張子. 存在しない場合はContent-Typeに等しい.
  FILE_EXTENSION = {
    "plain" => "txt", "richtext" => "rtf",
    "msword" => "doc", "javascript" => "js", "shockwave-flash" => "swf",
    "jpeg" => "jpg", "MP4A-LATM" => "m4a", "MP4V-ES" => "mp4",
    "quicktime" => "qt", "msvideo" => "avi",
    "ms-bmp" => "bmp",
  }
  # subtypeに対応するextensionを返す
  def self.get_extension subtype
    st = subtype.sub(/^x\-/,"")
    ext = FILE_EXTENSION[st] || st
    ".#{ext}"
  end
  
  
  #       split_content_type -> [Symbol,String,String] | nil
  # 
  # content_typeを解析して type, subtype, extension を返す.
  # 既に解析されている場合はそのまま.
  # e.g. 'text/html' => [ :text, "html", ".html" ]
  # content_typeがnilならnil
  def split_content_type
    @content_type ||= begin
      ct = content_type
      ct && (%r!^(\w+)/([\w\.\-]+)! =~ ct) &&
        [ $1.to_sym, $2, self.class.get_extension($2)]
    end
  end
  
  
  # type(e.g. :text)だけを返す
  def c_type
    split_content_type && split_content_type[0]
  end
  
  # ファイルの拡張子だけを返す. => nil | String
  def file_extension
    split_content_type && split_content_type[2]
  end
  
  # utf8に変換したbodyを返す
  def text; body && body.toutf8; end
  
  # ステータスコードを数値型で返す.
  def status; code.to_i; end
  
end


