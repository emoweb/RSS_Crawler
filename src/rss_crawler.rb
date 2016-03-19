#!/bin/ruby -Ku

require 'pathname'
srcdir = Pathname(__FILE__).dirname
require srcdir + 'lib/rsspipe'
require srcdir + 'lib/index_maker'
require 'time'
# pipes読み込み
(pdir = srcdir + 'pipes').opendir.each{|f|
  require pdir + f if f =~ /\.rb$/
}


class RSSCrawler
  def initialize conffile
    # config読み込み
    @conf = YAML.load_file(conffile)
    
    @logdir = Pathname(@conf[:log_directory])
    @logdir.mkpath
    #@logfile = @logdir + "#{Time.now.to_i}.log"
    @logfile = @logdir + "#{Time.now.strftime '%Y%m%d'}.log"
    
    @savedir = Pathname(@conf[:save_directory])
    @savedir.mkpath
    
    @logger = CrawlLogger.new(@logfile.to_s)
    @logger.def_progname = "main"
    
    # debugオプション. crawl前にpipeに転送される.
    @debug = {}
    
    # crawl時に例外を吐いた場合,それを記録
    @errors = []
  end
  attr_accessor :debug, :logger
  
  # nameのpipeをcrawlする
  def crawl_rss name
    proc = RSS_PIPES[name]
    if proc
      pipe = RSSPipe.new(@savedir, @logger, name, @conf[:fp_wait])
      pipe.debug.merge!(@debug) # オプション上書き
      proc.call(pipe)
    else
      @logger.error{ "#{name} is empty" }
    end
    
  rescue => e
    @logger.error_exception(name, e)
    @errors << [name, e, $@]
  end
  
  # multi threadでcrawl
  def crawl_all
    # rss crawl threads
    @cwth = @conf[:exe_pipes].collect{ |name|
      Thread.new(name){ |_name| crawl_rss(_name) }
    }
    
    # make & save index.html
    @logger.info{"make & save index.html"}
    s = make_index(@conf[:exe_pipes])
    IO.write((@savedir + 'index.html'), s)
    
    # kill timer
    @killtimer = Thread.new{
      sleep t = @conf[:timeout]
      @logger.warn{ "timeout (#{t}s)" }
      @cwth.each{|th| th.kill }
    }
    
    # wait for crawl
    @cwth.each{|th| th.join }
    
    # save errors
    if !@errors.empty?() && (eln = @conf[:error_log_name])
      @logger.info{ "save errors" }
      r = RSS20.new
      t = Time.now
      d = @errors.collect{ |name, e, place|
        "<strong>#{name}</strong><br/><p>" +
          CGI.escapeHTML(e.inspect) +
          "\nin\n" + CGI.escapeHTML(place.join("\n")) + "</p>"
      }.join('<br/><br/>')
      
      r.channel = { :title => "RSS Crawler Error Log", :link => " ", :description => " " }
      r.items << { :pubDate => t, :title => t.to_s(), :link => ' ', :description => d }
      
      savefile = @savedir + "#{eln}.xml"
      IO.write(savefile, r.to_xml)
    end
    
    
    @logger.info{ "complete" }
    
  rescue => e
    @logger.error_exception("crawl_all", e)
  end
  
  
  
end


if __FILE__ == $0
  RSSCrawler.new(srcdir + 'conf.yml').crawl_all
end

