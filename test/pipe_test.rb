#!/bin/ruby -Ku

# testconfで回すだけ

require 'pathname'
testdir = Pathname(__FILE__).dirname.expand_path
require_relative '../src/rss_crawler'

rc = RSSCrawler.new(testdir + 'testconf.yml')
rc.debug[:save_description] = true
rc.logger.loglevel = 3 # debug
rc.crawl_all
