require 'date'
require 'digest/md5'
require 'gelf'

class LogClient

  attr_reader :component, :host, :log_host, :log_port

  # regex that matches each log entry.
  # it's expected to have the following groups
  # \1 timestamp as TIMESTAMP_FORMAT
  # \2 process
  # \3 level
  # \4 class (the class generating the log entry
  # \5 log message
  # one day i'll make it more flexible
  LOG_LINE_FORMAT = /([\d]{4}-[\d]{2}-[\d]{2}\s[\d]{2}:[\d]{2}:[\d]{2},[\d]{3})\s<([^>]+)>\s\[([^\]\s]+)\s*\]\s\[([^\]\s]+)\s*\]\s(.+)/

  # the timestamp format of the log entry
  TIMESTAMP_FORMAT = "%Y-%m-%d %H:%M:%S,%L"

  # array of regexes with groups to scan the log message for extraction of additional fields
  ADDITIONAL_FIELDS_REGEXES = {
    /^.+deal[-\s]id=([^\],\s]+).+$/ => "_deal",
    /^.+session[-\s]id=([^\],\s]+).+$/ => "_session"
  }

  def initialize options, component, host
    log_server = options.log_server || "localhost:12201"
    data = log_server.split(":")
    @log_host = data[0]
    @log_port = data[1] || 12201
    @log_port = @log_port.to_i
    @component = component
    @host = host
    default_options = {}
    default_options['host'] = @host
    default_options['facility'] = @component
    max_chunk_size = 'LAN'
    @notifier = GELF::Notifier.new(@log_host, @log_port, max_chunk_size, default_options)
  end

  def notify log_line
    m = {}
    parse_line m, log_line
    result = @notifier.notify m
    m["sent"] = !result.nil?
    m
  end

  private

  def parse_line m, line
    # mandatory args
    data = line.scan(LOG_LINE_FORMAT).flatten
    m["facility"] = @component
    m["host"] = @host
    m["long_message"] = line
    m["timestamp"] = parse_timestamp(data[0]) || Time.now if data.length > 0
    m["_process"] = data[1] || 'unknown' if data.length > 1
    m["level"] = parse_level(data[2]) if data.length > 2
    m["_class"] = data[3] || 'unknown' if data.length > 3
    m["short_message"] = data[4] || line if data.length > 4
    m["_dup_id"] = Digest::MD5.hexdigest(line)
    parse_fields(m, m["short_message"])
  end

  def parse_timestamp ts
    d = Date._strptime(ts, TIMESTAMP_FORMAT)
    Time.utc(d[:year], d[:mon], d[:mday], d[:hour], d[:min], d[:sec], d[:sec_fraction], d[:zone])
  end

  def parse_level l
    begin
      eval "GELF::Levels::#{l}"
    rescue
      GELF::Levels::UNKNOWN
    end
  end

  def parse_fields m, line
    ADDITIONAL_FIELDS_REGEXES.each do | regex, field |
      data = line.scan(regex).flatten
      m[field] = data[0] unless data.empty?
    end
  end

end