#!ruby -Ku
# 単純なpipeはここで一括定義する.

require 'yaml'
conf = YAML.load_file(__FILE__.sub(/\.rb$/, '.yml'))

RSS_PIPES ||= {} if $0 == __FILE__

# pipe_procedure_1 だけで完結する場合
# [[name,url,filter_regex,xpath]] を読み込み定義
conf[:procedure_1].each{ |name, url, fr, xp|
  args = [url, (fr.empty? ? nil : Regexp.new(fr)), (xp.empty? ? nil : xp)]
  RSS_PIPES[name.to_sym] = Proc.new{|pipe| pipe.procedure_1(*args) }
}



#[
#  [
#    :excite_koneta,
#    'http://rss.rssad.jp/rss/excite/source/Excite',
#    /^PR:\s/,
#    '//div[@class="story"]'
#  ],
#  [
#    :excite_odd,
#    'http://rss.rssad.jp/rss/excite/odd',
#    nil,
#    '//div[@class="story"]'
#  ],
#  
#].each{ |name,*args|
#  RSS_PIPES[name] = Proc.new{|pipe| pipe.pipe_procedure_1(*args) }
#}
#
#



#RSS_PIPES[:excite_koneta] = Proc.new{ |pipe|
#  pipe.get_feed('http://rss.rssad.jp/rss/excite/source/Excite')
#  pipe.filtering{|item| item.title =~ /^PR:\s/ }
#  pipe.read_saved
#  pipe.fetch_page('//div[@class="story"]')
#  pipe.save_rss
#}
#RSS_PIPES[:excite_odd] = Proc.new{ |pipe|
#  pipe.get_feed 'http://rss.rssad.jp/rss/excite/odd'
#  pipe.read_saved
#  pipe.fetch_page('//div[@class="story"]')
#  pipe.save_rss
#}


#LIBDIR = File.join(File.expand_path(__FILE__), '../../lib/')
#require File.join(LIBDIR, 'rsspipe')


