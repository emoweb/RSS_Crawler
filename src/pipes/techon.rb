#!/bin/ruby -Ku

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
    # 有料記事検知
    a = h.xpath('//aside[@class="attention_members-only premium"]')
    unless a.empty? then
      item.title = "[premium] " + item.title
    end
    # 記事切り出し
    kj = h.xpath('//div[@class="kiji" or @id="kiji" or @class="article-body"]')
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
      [/%E2%80%9[CD]/, ''] # 全角の”が交じるとかいう糞みたいなミスをする記事があったためその対応
    ].each{ |pat,rep|
      html.gsub!(pat, rep || '')
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
    :feed => 'https://techon.nikkeibp.co.jp/rss/index.rdf',
    :fetch => proc{|item| f.fetch_techon(item)},
  }
  pipe.pipe_procedure(opt)
  
}

