#!ruby -Ku

require 'rss'
r1 = RSS::Parser.parse('z:/r1.rdf')
r2 = RSS::Parser.parse('z:/r2.rdf')


def rss_copy_channel src, dest
  %w!title description link about!.each{|sym|
    dest.channel.__send__(sym+"=", src.channel.__send__(sym))
  }
end
def rss_copy_item src, dest
    %w!title description link date!.each{|sym|
      dest.__send__(sym+"=", src.__send__(sym))
    }
end

# r1からタイトルがPR:から始めるアイテムをフィルタリングし,r2と結合
r = RSS::Maker.make("2.0"){|mk|
  rss_copy_channel(r1, mk)
  
  r1.items.each{|it|
    next if it.title =~ /^PR:\s/
    rss_copy_item(it, mk.items.new_item)
  }
  r2.items.each{|it| rss_copy_item(it, mk.items.new_item) }
}.to_s

IO.write("z:/test.rdf", r)

