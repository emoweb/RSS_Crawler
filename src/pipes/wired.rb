#!/bin/ruby -Ku

# Wired.jp
# http://wired.jp/
# 複雑化したため,独自pipeに

require 'uri'

class WiredFetcher
  def initialize pipe
    @pipe = pipe
    @base_u = URI('http://wired.jp/')
    # get_descriptionのoption
    opt_base = {
      :remxpath => [
        '//script',
        '//ul[@class="social-button-syncer"]',
      ],
      :replace => [
        /\r\n/,
        [/<div\s((class|style|id)=\"[^\"]*\"\s*)*>/, '<div>'],
        [/\s*([<>])\s*/, '\1'],
        [/<(div|p|span)\s((class|style|name|id)=\"[^\"]*\"\s*)*>/, '<\1>'],
        # imgタグをnoscriptのものに置換する
        [%r!<p><img[^>]*></p><noscript>(<img[^>]*>)</noscript>!, '\1'],
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
      return @pipe.get_description(item, @normal_opt)
    else
      # 特集記事の場合
      return @pipe.get_description(item, @article_opt)
    end
  end
  
end




RSS_PIPES[:wired] = Proc.new{ |pipe|
  f = WiredFetcher.new(pipe)
  opt = {
    :feed => 'http://wired.jp/feed/',
    :filter => '^PR:\s',
    :fetch => Proc.new{|i| f.fetch_wired(i)},
  }
  pipe.pipe_procedure(opt)  
}

