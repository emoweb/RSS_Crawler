#!/bin/ruby -Ku

# Wired.jp
# http://wired.jp/
# 複雑化したため,独自pipeに

require 'uri'
require 'kconv'

class WiredFetcher
  def initialize pipe
    @pipe = pipe
    @base_u = URI('http://wired.jp/')
    # get_descriptionのoption
    opt_base = {
      :remxpath => [
        '//script',
        '//ul[@class="social-button-syncer"]',
        '//section[@class="article-module-related"]',
        '//ul[@class="GL-thumbList"]',
        '//section[@class="article-tag-list"]',
      ],
      :replace => [
        /\r\n/,
        /<!--\s[^>]*\s-->/, # コメント削除
        [/<div\s((class|style|id)=\"[^\"]*\"\s*)*>/, '<div>'],
        [/\s*([<>])\s*/, '\1'],
        # クラス情報削除
        [/<(div|p|span|ul|li|article|h1)\s((class|style|name|id|data-\w+)=\"[^\"]*\"\s*)*>/, '<\1>'],
        # imgタグをnoscriptのものに置換する
        [%r!(<p>)?<img[^>]*>(</p>)?<noscript>(<img[^>]*>)</noscript>!, '\3'],
      ],
      :abslink => true,
    }
    @normal_opt = opt_base.merge({
      :xpath => '//article[@class="article-detail"]',
    })
    @article_opt = opt_base.merge({
      :xpath => '//main/article',
    })
  end
  
  def fetch_wired item
    # たまに先頭のwired.jpが省略されるため,その対応をする.
    link = @base_u + URI(item.link)
    item.link = link.to_s
    # itemのURL形式で種別を判断しfetch
    case link.path
    when %r!^/\d{4}/\d{2}/\d{2}/!
      # 通常の場合
      return @pipe.get_description(item, @normal_opt).to_s.toutf8
    else
      # 特集記事の場合
      return @pipe.get_description(item, @article_opt).to_s.toutf8
    end
  end
  
end




RSS_PIPES[:wired] = Proc.new{ |pipe|
  f = WiredFetcher.new(pipe)
  opt = {
    :feed => 'https://wired.jp/rssfeeder/',
    :filter => '^PR:\s',
    :fetch => Proc.new{|i| f.fetch_wired(i)},
  }
  pipe.pipe_procedure(opt)  
}

