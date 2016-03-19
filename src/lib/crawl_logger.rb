#!/bin/ruby -Ku

require 'mutex_m'

# Crawlログ(csv)の作成用.
# Loggerの場合は色々と不便なため作成.
# マルチスレッドでの同期等を実装.
class CrawlLogger
  include Mutex_m
  
  def self.close_file f; proc{ f.close unless f.closed? }; end
  
  # loglevelは0:error, 1:warn, 2:info, 3:debug. ex)2ならdebugはカット
  def initialize logfile, stdout = true, loglevel = 2
    super() # Mutex_mの初期化
    
    @loglevel = loglevel
    f = open(logfile, "a")
    @out = [f]
    @out << STDOUT if stdout
    @def_progname = " "
    @linelog = [] # 行数単位で読めるように
    w2 "date,progname,severity,message"
    
    ObjectSpace.define_finalizer(self, self.class.close_file(f))
  end
  attr_accessor :def_progname, :loglevel
  attr_reader :linelog
  
  # write out
  def w msg
    mu_synchronize{ @out.each{ |o| o.puts msg } }
  end
  
  # debug write out. syncでの待ち時間を表示する.
  # nextlineは2行以上のログのため.
  def w2 mes, nextline = ""
    t = Time.now
    mu_synchronize{
      mes = "%s,%.3fs late%s" % [mes, (Time.now - t), nextline]
      @out.each{ |o| o.puts mes }
      @linelog << mes
    }
  end
  
  
  def log severity, progname = @def_progname, &log_mes_gen
    datetime = Time.now
    
    mes, nextline = if (logdata = log_mes_gen.call).is_a?(Enumerable) then
      a = logdata.to_a
      n = a[1..-1].collect {|s| "-,-,-,#{s.chomp},-" }.join("\n")
      [a[0], "\n" + n]
    else
      [logdata, ""]
    end
    
    w2("%s.%03d,%s,%s,%s" % [
      (datetime.strftime '%H:%M:%S'), (datetime.usec / 1000),
      progname, severity, mes
    ], nextline)
  end
  
  # 記録用
  def error progname = @def_progname, &log_mes_gen
    log("ERROR", progname, &log_mes_gen)
  end
  def warn progname = @def_progname, &log_mes_gen
    log("WARN", progname, &log_mes_gen) if 0 < @loglevel
  end
  def info progname = @def_progname, &log_mes_gen
    log("INFO", progname, &log_mes_gen) if 1 < @loglevel
  end
  def debug progname = @def_progname, &log_mes_gen
    log("DEBUG", progname, &log_mes_gen) if 2 < @loglevel
  end
  
  def error_exception place, exception
    error(place){ [*(exception.inspect.lines.to_a), "@", *$@] }
  end
  
end





