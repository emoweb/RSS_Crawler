#!ruby -Ku
# 単純なpipeはここで一括定義する.

require 'yaml'
conf = YAML.load_file(__FILE__.sub(/\.rb$/, '.yml'))

RSS_PIPES ||= {} if $0 == __FILE__

conf[:pipe_procedure].each{|name, opt|
  RSS_PIPES[name.to_sym] = Proc.new{|pipe|
    pipe.pipe_procedure(opt)
  }
}
