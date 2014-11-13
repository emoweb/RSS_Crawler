#!ruby -Ku

LIBDIR = File.join(File.expand_path(__FILE__), '../../src/lib/')
require File.join(LIBDIR, 'rsspipe')

lg = CrawlLogger.new('z:/getrss.log')
rp = RSSPipe.new(Pathname('z:/'), lg, 'testrss')

rp.get_feed('http://www.excite.co.jp/News/xml/rss_excite_news_bit_index_utf_8.dcg')
rp.filtering{|item| item.title =~ /^PR:\s/ }
rp.read_saved
rp.save_rss


