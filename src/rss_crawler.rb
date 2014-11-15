#!ruby -Ku

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
    @logfile = @logdir + "#{Time.now.to_i}.log"
    
    @savedir = Pathname(@conf[:save_directory])
    @savedir.mkpath
    
    @logger = CrawlLogger.new(@logfile.to_s)
    @logger.def_progname = "main"
  end
  
  # nameのpipeをcrawlする
  def crawl_rss name
    proc = RSS_PIPES[name]
    if proc
      proc.call( RSSPipe.new(@savedir, @logger, name) )
    else
      @logger.error{ "#{name} is empty" }
    end
    
  rescue => e
    @logger.error_exception(name, e)
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
    @logger.info{ "complete" }
    
  rescue => e
    @logger.error_exception("crawl_all", e)
  end
  
  
  
end


if __FILE__ == $0
  RSSCrawler.new(srcdir + 'conf.yml').crawl_all
end

