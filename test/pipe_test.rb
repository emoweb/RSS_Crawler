#!ruby -Ku

# testconfで回すだけ

require 'pathname'
testdir = Pathname(__FILE__).dirname.expand_path
require testdir + '../src/rss_crawler'

rc = RSSCrawler.new(testdir + 'testconf.yml')
rc.debug[:save_description] = true
rc.crawl_all
