#!/bin/bash

# pingのstdoutが空ならWAN接続なし
r=`ping -c 1 -w 1 www.google.com`
if [ ! -z "$r" ]; then
  ${0%/*}/src/rss_crawler.rb
  
  # 出力をGitHub Pagesへcommit
  pushd /data/var/rssc_log/
  git add . && git commit -m "update" && git push
fi




