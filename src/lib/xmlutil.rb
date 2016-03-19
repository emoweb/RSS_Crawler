#!/bin/ruby -Ku

require 'nokogiri'

class Nokogiri::XML::NodeSet
  def remove_xpath xp
    self.xpath(xp).each{ |nd|
      p = nd.parent
      p.children = p.children.tap{|c| c.delete(nd) }
    }
  end
end
