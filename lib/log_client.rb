require 'gelf'

class LogClient
  attr_accessor :data
  def initialize options, component, host
    log_server = options.log_server || "localhost:21012"
    data = log_server.split(":")
    @log_host = data[0]
    @log_port = data[1] || "21012"
    @component = component
    @host = host
  end

  def notify log_line
    m = GelfMessage.new
    m.facility=@component
    m.host=@host
    data = parse_line log_line
    m.short_message = data["short_message"]
    m.long_message = data["long_message"]
    m.timestamp = data["timestamp"]
    m.version = "1.0"
    m.fields = {}
    data["fields"].each { | f, v | m.fields[f] = v }

  end

end