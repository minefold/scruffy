require 'time'

class Logger
  def initialize meta_data = {}
    @meta_data = meta_data
  end

  def info data
    out('info', data)
  end
  
  def error e, data
    data["error"] = e
    out("error", data)
  end

  def out level, data
    data = @meta_data.merge(data).merge(
      level: level,
      ts: DateTime.now.rfc3339
    )
    print_log data
  end

  def print_log data
    if ENV['LOGFMT'] != 'human'
      print_log_json data
    else
      print_log_human data
    end
  end

  def print_log_json data
    puts JSON.dump(data)
  end

  def print_log_human data
    attrs = data.select {|k,v|
      ![:ts, :level, :event].include?(k)
    }.map{|k,v| "#{k}=#{quote_unspaced v}"}.sort
    
    puts "#{data[:ts]} [#{data[:level]}] #{data[:event]} #{attrs.join(' ')}"
  end
  
  def quote_unspaced s
    s.to_s.include?(' ') ? %Q{"#{s}"} : s
  end
end
