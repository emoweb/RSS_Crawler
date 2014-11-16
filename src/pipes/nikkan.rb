#!ruby -Ku
 
# 日刊工業新聞社
# http://www.nikkan.co.jp/

# RDFが不正でパースできないことが判明

#RSS_PIPES[:nikkan] = Proc.new{ |pipe|
#  pipe.procedure_1('http://www.nikkan.co.jp/rss/nksrdf.rdf', nil, nil){|html|
#    html =~ /<!-- ■抄録文■ -->(.*)<!-- e-nikkan -->/
#    $1
#  }
#}

#RSS_PIPES ||= {} if $0 == __FILE__



