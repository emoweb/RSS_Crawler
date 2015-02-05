#!ruby -Ku

# 日経テクノロジーオンライン
# http://techon.nikkeibp.co.jp/
# Loginが必要なため,必要ない部分のみ回収

class TechonFetcher
  def initialize pipe
    @pipe = pipe
  end
  
  def fetch_techon item
    r = @pipe.page_access(item.link)
    return nil unless r
    h = Nokogiri::HTML(r.text)
    kj = h.xpath('//div[@id="kiji"]')
    pg = h.xpath('//div[@class="paging"]')
    link = r.access_url
    return wash_page(kj.to_s, link) +
      (pg ? wash_page(pg.to_s, link) : '')
  end
  
  def wash_page html, link
    # タグ等削除
    [
      /[\r\n]/, [/\s*([<>])\s*/, '\1'],
      [/(<\w+)\sclass=\"[^\"]+">/, '\1>'],
    ].each{ |reg,rep|
      html.gsub!(Regexp.new(reg), rep || '')
    }
    # リンク変換
    base = URI.parse(link)
    html.gsub!(/\s(href|src)=\"([^\"]+)\"/) {
      %Q! #{$1}="#{base.merge($2)}"!
    }
    return html
  end
  
end





RSS_PIPES[:techon] = Proc.new{ |pipe|
  f = TechonFetcher.new(pipe)
  opt = {
    :feed => 'http://techon.nikkeibp.co.jp/rss/index.rdf',
    :fetch => proc{|item| f.fetch_techon(item)},
  }
  pipe.pipe_procedure(opt)
  
}

