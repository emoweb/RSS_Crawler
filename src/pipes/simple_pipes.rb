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

# pipe_procedure_1による取得と,正規表現による本文抜き出しを行う場合


