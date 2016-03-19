#!/bin/ruby -Ku
# RSSを登録するときのindex of を作る.
#require 'eruby'

INDEX_TEMPLATE = <<IDXT
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
<html><head><title>Index of RSS feeds</title></head><body>
<h1>Index of RSS feeds</h1>
<pre><hr>%s
<hr></pre>
</body></html>
IDXT


def make_index name_list
  r = name_list.collect{ |name|
    %Q!<a href="./#{name}.xml">#{name}.xml</a>!
  }.join("\n")
  INDEX_TEMPLATE % r
end



