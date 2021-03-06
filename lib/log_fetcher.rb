require 'ostruct'
require File.join(File.dirname(__FILE__), 'connection.rb')
require File.join(File.dirname(__FILE__), 'fetcher_command.rb')

class LogFetcher
  
  @@id = 0
  
  # host time adj = 'date +%-::z'
  attr_reader :context, :datetime_mask, :time_mask, :id
  attr_accessor :progress_listener, :sent, :to_send
  def initialize options, context, progress_listener
    @id = @@id
    @@id = @@id + 1
    @sent = 0
    @to_send = 0
    @options = options
    raise "options are mandatory" if @options.nil?
    raise "time option is mandatory" if @options.time.nil?
    raise "timewindow option is mandatory" if @options.timewindow.nil?
    @datetime_mask = build_regex_mask(@options.time.to_s, (@options.time + @options.timewindow).to_s)
    @time_mask = build_regex_mask(extract_time(@options.time), extract_time(@options.time + @options.timewindow))

    @context = context
    @context.freeze
    raise "file is mandatory" if @context["file"].nil?
    raise "username is mandatory" if @context["username"].nil?
    raise "host is mandatory" if @context["host"].nil?
    @log_file = ""
    @log_file << @context["logs_dir"] << "/" unless @context["logs_dir"].nil?
    @log_file << @context["file"]
    @progress_listener = progress_listener
    @connection = Connection.new :host=> @context["host"], :user => @context["username"], :verbose => options.verbose, :key => @options.keyfile
  end

  def utc_time_adjustment host
    result = @connection.execute context, 'date +%::z'
    raise "Invalid result from remote host" if result.nil?
    parts = result.scan(/(.)(\d\d):(\d\d):(\d\d)/)[0]
    parts[0] = "#{parts[0]}1"
    parts[0].to_i * (3600 * (parts[1].to_i) + 60 * parts[2].to_i + parts[3].to_i)
  end

  # builds a regular expression that matches all the strings lexicografically between start and finish
  def build_regex_mask(start, finish)
    s = ""
    start_a, end_a = start.to_s.split(//), finish.split(//)
    start_a.each_with_index do | x, y |
      if x == end_a[y]
        s << end_a[y]
      else
        start_c = start_a[y].to_i
        end_c = end_a[y].to_i
        s << "["
        (start_c .. end_c).each { | i | s << i.to_s }
        s << "]+"
        break
      end
    end
    /#{s}/
  end

  def start &block
    raise "fetcher already started" unless @worker.nil?
    raise "no block given for processing fetched data" unless block_given?
    raise "the given block must have arity equal to one" if block_given? && block.arity != 2
    @worker = Thread.new do
      command = build_command
      @progress_listener.puts "Fetcher[#{@id}] started. host:'#{@context["host"]}', user:'#{@context["username"]}', logfile:'#{@log_file}', command:'#{command}'"
      result = @connection.execute command, @progress_listener do | data |
        data.each_line do | line |
          block.call(@progress_listener, line)
        end
      end
    end
  end

  def wait_completion
    @worker.join unless @worker.nil?
  end

  private

  def extract_time(time)
    a = time.to_s.split(/ /)
    a[1]
  end

  def build_command
    fetcher_command = FetcherCommand.new :log_file => substitute_time_patterns(@log_file), :datetime_mask => @datetime_mask.source, :tokens => @context["tokens"]
    fetcher_command.command
  end

  def substitute_time_patterns string
    @options.time.strftime(string)
  end
end