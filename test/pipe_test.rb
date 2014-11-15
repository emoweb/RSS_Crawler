#!ruby -Ku

# testconfで回すだけ

require 'pathname'
testdir = Pathname(__FILE__).dirname.expand_path
require testdir + '../src/rss_crawler'

RSSCrawler.new(testdir + 'testconf.yml').crawl_all
