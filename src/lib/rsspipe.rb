#!/bin/ruby -Ku
# 必要な関数まとめ

require 'pathname'
libpath = Pathname(__FILE__).dirname
require libpath + 'httputil'
require libpath + 'crawl_logger'
require libpath + 'rss20'
require libpath + 'xmlutil'

require 'rss'
require 'set'
require 'kconv'
require 'nokogiri'

# name(symbol) => RSSPipe Proc の形式でPipeを登録していく.
# Procは情報を元に生成されたRSSPipeのinstanceを受け取り,
# get_feed(s)からsaveまでの処理をする.
RSS_PIPES = {}

# RSSを取得し,加工・ファイル出力する.
# 1出力feed につき 1 instance
# 前回の出力が残っている場合,更新部分のみ加工する.
# 確認はpubdateで行う.
# 
# 一般的には
# initialize -> get_feed(s) -> {filtering} -> read_saved -> {fetch_page} -> save
# の順で処理を行う. {}の中は任意.
class RSSPipe
  # savedir: フィードファイル保存先.
  # logger: log用のinstance. 他のRSSPipe instanceと共有してもOK.
  # name: フィード名. ファイル名やlogに使われる.
  # wait: fetch pageでのsleep時間. classで共通
  def initialize savedir, logger, name, wait = -1
    @name = name
    @savedir = savedir
    @savefile = savedir + "#{@name}.xml"
    @l = logger
    @dl_items = []
    @updated = [] # 更新されたRSSアイテム
    @saved = []   # 以前からあったアイテム
    @deleted = [] # 保存されていたが取得したフィードに無いアイテム
    @channel = {} # チャンネル情報. :title, :description, :link, :about を保有.
    @wait = wait  # fetch_pageの間隔
    # debug設定. 標準は全てfalse.
    @debug = {}
  end
  attr_reader :updated, :channel
  attr_accessor :wait
  attr_accessor :debug
  
  def info &bk; @l.info(@name, &bk); end
  def error_log &bk; @l.error(@name, &bk); end
  
  # フィードを取得し, @dl_items に結合. set_channel = T なら channelも移す.
  # urlにはRSS::Parser.parseに渡せる形式ならなんでも渡せる.
  # なお,StringならURI, IOStreamならIOとして展開されるようだ.
  def get_feed url, set_channel = true
    # feedをparseして追加
    info{"access: #{url} "}
    r = RSS::Parser.parse(url)
    @dl_items.concat(r.items)
    
    # channelをset
    if set_channel then
      # 共通項目をコピー
      ch = r.channel
      [:title, :description, :link].each{|sym|
        @channel[sym] = ch.__send__(sym)
      }
      # RSS1.0等の場合はaboutが定義されていないため,linkで代用
      rss1 = ch.methods.grep(/about/).empty?
      @channel[:about] = rss1 ? ch.link : ch.about
      
      info{"set channel: #{@channel[:title]}"}
    end
  end
  
  # 直接items(RSS::Rss::Channel::Item)のArrayを渡す場合
  attr_accessor :dl_items
  
  # 前回取得した分を読み出し,
  # 更新された部分を @updated, 読み出し分にしか存在しない分を @deleted,
  # どちらにも存在する分を @saved に分類する. @saved には読み出し分が入る.
  # compare_f はitem重複比較用のProc.
  def read_saved compare_f = Proc.new{ |i| i.date || i.dc_date }
    # ファイル読み込み
    prev = if @savefile.file?
      info{ 'cache loading'}
      begin
        RSS::Parser.parse(@savefile).items
      rescue => e
        error_log{ "faild to cache loading : #{e}" }
        []
      end
    else
      info{ 'The preview of results is empty'}
      []
    end
    
    # 重複検出set生成関数
    def mkset items, cf
      Set.new items.collect{|i| cf.call(i) }
    end
    # 重複検出setを生成(sdl:download分, ssv:保存済み分)
    sdl, ssv = mkset(@dl_items, compare_f), mkset(prev, compare_f)
    
    # 分類
    @dl_items.each{|i|
      @updated.push(i) unless ssv.include?(compare_f.call(i))
    }
    prev.each { |i|
      (sdl.include?(compare_f.call(i)) ? @saved : @deleted).push(i)
    }
    info{
      "classification completed. update:#{@updated.size}" +
        " non-updated:#{@saved.size} deleted:#{@deleted.size}"
    }
  end
  
  # 保存対象(@updated, @saved)よりRSSを生成し,保存する.
  def save_rss
    # updateが無い場合はskip
    if @updated.empty?
      @l.info(@name){ 'save RSS : skip'}
      return
    end
    
    @l.info(@name){ 'save RSS' }
    
    r = RSS20.new
    r.channel = @channel
    r.items = @updated.dup.concat(@saved).collect{ |item|
      h = {:pubDate =>  item.date || item.dc_date }
      [:title, :link, :description].each{ |sym| h[sym] = item.__send__(sym) }
      h
    }
    
    IO.write(@savefile, r.to_xml)
    @l.info(@name){ 'complete' }
  end
  
  # @dl_items をフィルタリングする. blockが true を返したitemを全て落とす.
  def filtering &block
    befs = @dl_items.size
    @dl_items.delete_if{ |i| block.call(i) }
    info{"filterd: #{befs} -> #{@dl_items.size}"}
  end
  
  #       pipe_procedure(options) -> nil
  # 
  # 一般的なpipe処理を行う. 大抵のpipeはこれのみで処理が可能.
  # オプションは省略が容易なようにHashで渡す.
  # 使えるオプションは下記の通り.
  # :fetchについてはfetchメソッドを参照.
  # なお,Regexpを渡すところにStringを渡した場合はRegexpに変換される.
  # 
  # :feed => String | StringIO
  # フィードのURL. StringならURIとして,StringIOならStringとして展開.
  # 
  # :filter => nil | Regexp | Proc
  # Regexpならtitleと比較し一致すれば除外,
  # Procならitemを渡し,真を返せば除外する.
  # 
  def pipe_procedure options = {}
    # :feed
    get_feed(options[:feed])
    
    # :filter
    filter = options[:filter]
    case filter
    when Regexp, String
      filter = Regexp.new(filter)
      filtering{|item| item.title =~ filter }
    when Proc
      filtering(&filter)
    end
    
    # 以前の処理内容を読み込み
    read_saved
    
    # :fetch
    fetch(options[:fetch])
    
    # 出力
    save_rss
    return nil
  end
  
  
  #   fetch(nil | Proc | {
  #     :xpath => String
  #     :remxpath => [String]
  #     :replace => [Regexp | [Regexp, String]]
  #     :edit => Proc
  #     :abslink => True | False
  #     :get_title => True | False | Proc
  #     :update_url => False | True | String
  #   }) => nil
  # 
  # nilならfetch処理は行わない.
  # 
  # Procを渡した場合,そのProcにitemを渡し,戻り値をdescriptionにセットする.
  # ただし偽を返した場合はdescriptionを編集しない.
  # titleの更新が必要な場合はProc中で行う.
  # 
  # Hashを渡した場合,オプションに従いHTMLを加工する.
  # :xpath    : 指定したXPathでHTMLから抜き出しを行う.
  # :remxpath : xpathでマッチした要素を削除する.
  # :relpace  : 各要素を評価しgsubしていく.Stringを省略時は''として扱う.
  # :edit     : ProcにHTMLを渡し,戻り値をHTMLとする.
  # :abslink  : 相対リンクを絶対リンクに変換するか.
  # :get_title: 真ならページのtitle要素に従ってtitleを更新する.
  #   ProcならProcにtitle要素を渡して戻ってきた値をtitleとする.
  # :update_url: 偽以外ならitemのURLをfetchで最終的にアクセスしたURLに書き換える.
  #   Stringの場合はオプションとして解釈する.
  #   'rm_query' : URLのCGIオプションを削除する.
  # 
  # 複数オプションを指定した場合,加工された内容が次に渡されていく.
  # 処理順は :get_title -> :xpath -> :relpace -> :edit -> :abslink
  # また,:fetchに渡すHashの全てのオプションは省略可能.
  # なお,Regexpを渡すところにStringを渡した場合はRegexpに変換される.
  # 
  def fetch options
    return nil unless options
    
    # proc生成
    fetch_proc = case options
    when Proc; options
    when Hash; proc{ |item| get_description(item,options) }
    end
    
    # ページを順に読み込み
    @updated.each_with_index { |item, idx|
      info{ "fetch page #{idx +1}/#{@updated.size}" }
      item.description = fetch_proc.call(item) || item.description
      
      # debug用. descriptionを個別保存.
      if @debug[:save_description]
        IO.write(@savedir + "#{@name}-#{idx}.html", item.description)
      end
    }
  end
  
  #   get_description(String|Items, Hash) => String | nil
  # 
  # Itemsは RSS::Rss::Channel::Items のこと.
  # Stringで無い場合はItemsとして扱われる.
  # HTMLを処理しdescriptionを返す. 引数はURLと:fetchのHash.
  def get_description item, opt
    # itemがStringであることのflag
    stritem = item.is_a?(String)
    
    # itemのclassを判断
    url = stritem ? item : item.link
    
    # get web page. 失敗時はnilにする.
    res = page_access(url)
    return nil unless res
    r = res.text
    
    # title更新flag
    get_title = (!stritem) && opt[:get_title]
    # Nokogiriパース
    xp = (get_title || opt[:xpath] || opt[:remxpath]) && Nokogiri::HTML(r)
    
    # title更新
    if get_title
      # procの場合はtitleをprocで加工して適用
      gtp = opt[:get_title].is_a?(Proc) ? opt[:get_title] : proc{|v|v}
      item.title = gtp.call(xp.xpath('//title').text)
    end
    
    # URL更新処理
    upurl = opt[:update_url]
    if (!stritem) && upurl then
      u = res.access_url
      u.sub!(/\?.*$/, '') if(upurl == 'rm_query')
      item.link = u
    end
    
    # XPath適用. nil(=マッチなし)なら戻る.
    if xp
      xp = xp.xpath(opt[:xpath]) if opt[:xpath]
      
      # remove xpath
      rxpa = opt[:remxpath] || []
      rxpa.each{ |rxp|
        xp.remove_xpath(rxp)
      }
      
      r = xp.to_s
      return nil if r.empty?
    end
    
    # Regex relplace
    reparr = opt[:replace] || [] # nilなら空配列を処理
    reparr.each{ |reg, rep|
      r.gsub!(Regexp.new(reg), rep || '')
    }
    
    # edit for proc
    r = opt[:edit].call(r) if opt[:edit]
    
    # リンク変換
    if r && opt[:abslink]
      base = URI.parse(res.access_url)
      #debug{ base.to_s }
      begin
        r.gsub!(/\s(href|src)=\"([^\"]+)\"/) {
          #@l.debug{ "#{$2} -> #{base.merge($2)}" }
          %Q! #{$1}="#{base.merge($2)}"!
        }
      rescue => e
        error_log{ "abs link failed : #{e}" }
      end
    end
    
    # return
    r
  end
  
  #   page_access(String,Ture|False) => String | HTTPResponse
  # 
  # ページにアクセスし,結果を返す.
  def page_access url
    info{ "HTTP get #{url} "}
    res = HTTPUtil.get(url)
    info{ "status : #{res.status}" }
    return nil if(res.status / 100 != 2)
    (@wait > 0) && sleep(@wait)
    return res
  end

  
end
