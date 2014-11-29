#!ruby -Ku
# 必要な関数まとめ

require 'pathname'
libpath = Pathname(__FILE__).dirname
require libpath + 'httputil'
require libpath + 'crawl_logger'

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
  
  # フィードを取得し, @dl_items に結合. set_channel = T なら channelも移す.
  # urlにはRSS::Parser.parseに渡せる形式ならなんでも渡せる.
  # なお,StringならURI, IOStreamならIOとして展開されるようだ.
  def get_feed url, set_channel = true
    info{"access: #{url} "}
    r = RSS::Parser.parse(url)
    @dl_items.concat(r.items)
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
  
  # 前回取得した分を読み出し,
  # 更新された部分を @updated, 読み出し分にしか存在しない分を @deleted,
  # どちらにも存在する分を @saved に分類する. @saved には読み出し分が入る.
  # compare_f はitem重複比較用のProc.
  def read_saved compare_f = Proc.new{ |i| i.date }
    # ファイル読み込み
    prev = if @savefile.file?
      @l.info(@name){ 'cache loading'}
      RSS::Parser.parse(@savefile).items
    else
      @l.info(@name){ 'The preview of results is empty'}
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
      if sdl.include?(compare_f.call(i)) then
        @saved
      else
        @deleted
      end.push(i)
    }
    info{
      "classification completed. update:#{@updated.size}" +
        " non-updated:#{@saved.size} deleted:#{@deleted.size}"
    }
  end
  
  # 保存対象(@updated, @saved)よりRSSを生成し,保存する.
  def save_rss
    @l.info(@name){ 'make & save RSS' }
    r = RSS::Maker.make("2.0"){|mk|
      # channelを設定
      @channel.each{|k,v| mk.channel.__send__("#{k}=", v) }
      # itemを追加
      items = @updated.dup.concat(@saved).sort{ |i1,i2| i1.date <=> i2.date }
      items.each{|itm|
        ni = mk.items.new_item
        %w!title description link date!.each{|sym|
          ni.__send__("#{sym}=", itm.__send__(sym))
        }
      }
    }.to_s
    
    IO.write(@savefile, r)
    @l.info(@name){ 'complete' }
  end
  
  # @dl_items をフィルタリングする. blockが true を返したitemを全て落とす.
  def filtering &block
    befs = @dl_items.size
    @dl_items.delete_if{ |i| block.call(i) }
    info{"filterd: #{befs} -> #{@dl_items.size}"}
  end
  
  # get_feed, filtering, read_saved, fetch_page, save_rss の一連の流れを行う.
  # filterはtitleをregexで確認する. filter_regexがnilの場合はskipする.
  # xpathかblockを渡した場合,その引数でfetch_pageを行う.
  def procedure_1 feed_url, filter_regex, xpath, &block
    pipe_procedure({
        :feed => feed_url,
        :filter => filter_regex,
        :fetch => (block_given? || xpath) && {
          :xpath => xpath,
          :edit => block
        }
    })
  end
  
  #       pipe_procedure(options) -> nil
  # 
  # 一般的なpipe処理を行う. 大抵のpipeはこれのみで処理が可能.
  # オプションは省略が容易なようにHashで渡す.
  # 使えるオプションは下記の通り.
  # 
  # :feed => String | StringIO
  # フィードのURL. StringならURIとして,StringIOならStringとして展開.
  # 
  # :filter => nil | Regexp | Proc
  # Regexpならtitleと比較し一致すれば除外,
  # Procならitemを渡し,真を返せば除外する.
  # 
  # :fetch => nil | Proc | {
  #   :xpath => String
  #   :replace => [Regexp | [Regexp, String]]
  #   :edit => Proc
  # }
  # このオプションが偽でない場合,feedのlinkを読み込む.
  # Procを渡した場合,そのProcにlinkを渡し,返り値をdescriptionにセットする.
  # ただし偽を返した場合はdescriptionを編集しない.
  # Hashを渡した場合,オプションに従いHTMLを加工する.
  # :xpath : 指定したXPathでHTMLから抜き出しを行う.
  # :relpace : 各要素を評価しgsubしていく.Stringを省略時は''として扱う.
  # :edit : ProcにHTMLを渡し,戻り値をHTMLとする.
  # 複数オプションを指定した場合,加工された内容が次に渡されていく.
  # 処理順は :xpath -> :relpace -> :edit
  # また,:fetchに渡すHashの全てのオプションは省略可能.
  # なお,Regexpを渡すところにStringを渡した場合はRegexpに変換される.
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
  
  
  #   fetch(Hash|Proc|nil) -> nil
  # 
  # optionsはpipe_procedureの:fetchそのもの.
  def fetch options
    return nil unless options
    
    # proc生成
    fetch_proc = case options
    when Proc; options
    when Hash; proc{ |url| get_description(url,options) }
    end
    
    # ページを順に読み込み
    @updated.each_with_index { |item, idx|
      info{ "fetch page #{idx +1}/#{@updated.size}" }
      item.description = fetch_proc.call(item.link) || item.description
      
      # debug用. descriptionを個別保存.
      if @debug[:save_description]
        IO.write(@savedir + "#{@name}-#{idx}.html", item.description)
      end
    }
  end
  
  #   get_description(String, Hash) => String | nil
  # 
  # HTMLを処理しdescriptionを返す. 引数はURLと:fetchのHash.
  def get_description url, opt
    # get web page. 失敗時はnilにする.
    r = page_access(url)
    return nil unless r
    
    # XPath
    r = Nokogiri::HTML(r).xpath(opt[:xpath]).to_s if opt[:xpath]
    return nil unless r
    
    # Regex relplace
    reparr = opt[:replace] || [] # nilなら空配列を処理
    reparr.each{ |reg, rep|
      r.gsub!(Regexp.new(reg), rep || '')
    }
    
    # edit for proc
    r = opt[:edit].call(r) if opt[:edit]
    
    # return
    r
  end
  
  #   page_access(String,Ture|False) => String | nil
  # 
  # ページにアクセスし,結果を返す.
  def page_access url
    info{ "HTTP get #{url} "}
    res = HTTPUtil.get(url)
    info{ "status : #{res.status}" }
    return nil if(res.status / 100 != 2)
    (@wait > 0) && sleep(@wait)
    return res.text
  end
  
    
  # fetch_page(xpath = nil, wait = 3, &block) -> int
  # 
  # @updated を全文取得してdescriptionを書き換え,要素数を返す.
  # xpathを指定した場合,xpathでの抜き出しも行う.
  # blockを指定した場合,descriptionをblockで編集する
#  def fetch_page xpath = nil, &block
#    @updated.each_with_index { |item, idx|
#      info{ "fetch page #{idx +1}/#{@updated.size} : #{item.link} " }
#      r = HTTPUtil.get(item.link)
#      
#      info{ "status : #{r.status}" }
#      next if(r.status / 100 != 2)
#      
#      html = r.text
#      html = xpath ? Nokogiri::HTML(html).xpath(xpath).to_s : html
#      item.description = block_given? ? block.call(html) : html
#      
#      (@wait > 0) && sleep(@wait)
#    }
#  end
  
end
