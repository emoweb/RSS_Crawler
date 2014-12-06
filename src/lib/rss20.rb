#!ruby -Ku

# Ruby標準のRSSライブラリの代替.
# ドキュメントが無い上にCDATAでエンコードしてくれないため自作.

require 'cgi'
require 'time'

# RSS2.0のxmlを読み書きする.
# 内容はIO時にHTMLエスケープされるため,内部では平文で利用できる.
# itemsの形式は,
# [{:title=>String, :link=>String, :description=>String, :pubDate=>Time}]
# channelは,
# {:title=>String, :link=>String, :description=>String}
# itemsのdescriptionはCDATAで扱われる.
# 今の所は出力専用
class RSS20
  attr_accessor :channel, :items
  
  def initialize
    @channel = {}
    @items = []
  end
  
  XML_HEAD = "<?xml version='1.0' encoding='UTF-8'?>\n" +
    "<rss version='2.0'>\n\t<channel>\n"
  XML_TAIL = "\t</channel>\n</rss>"
  
  # XMLを生成
  def to_xml
    # channel情報
    chinfo = [:title, :link, :description].collect{|sym|
      "\t\t<#{sym}>#{CGI.escapeHTML(@channel[sym])}</#{sym}>\n"
    }
    
    # items生成. dateでソートしてからstring化.
    istr = @items.sort{ |i1,i2|
      i1[:pubDate] <=> i2[:pubDate]
    }.collect{ |item| item_to_str(item) }
    
    # xml生成
    [XML_HEAD, *chinfo, *istr, XML_TAIL].join('')
  end
  
  # 単独itemからXMLを生成
  def item_to_str item
    [
      "\t\t<item>\n",
      "\t\t\t<title>#{CGI.escapeHTML(item[:title])}</title>\n",
      "\t\t\t<link>#{CGI.escapeHTML(item[:link])}</link>\n",
      "\t\t\t<description><![CDATA[#{item[:description]}]]></description>\n",
      "\t\t\t<pubDate>#{item[:pubDate].rfc2822}</pubDate>\n",
      "\t\t</item>\n",
    ].join('')
  end
  
end

