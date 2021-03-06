require File.dirname(__FILE__) + '/version.rb'
require 'singleton'
require 'optparse'
require 'optparse/time'
require 'ostruct'
require 'pp'

class OptParser

  def self.options
    @@options
  end
    
  def self.parse(args)
    # The options specified on the command line will be collected in *options*.
    # We set default values here.
    options = OpenStruct.new
    options.environments = []
    options.localities = []
    options.components = []
    options.hosts = []
    options.accept_defaults = false
    options.time = nil
    options.timewindow = 60
    options.keyfile = ENV["PRIVATE_KEY"]
    options.tokens = []
    options.verbose = false
    options.deployment_json = nil
    options.show = false
    options.log_server = "localhost:12201"
    options.concurrent_connections = 5
    options.time = Time.new.utc - 60

    opts = OptionParser.new do |opts|
      opts.banner = "Usage: fetcher.rb -f FILE -T TIME [options]"

      opts.separator ""
      opts.separator "Specific options:"

      opts.on("-f", "--deployment-file FILE", 
        "The file containing the deployment database. The file is expected to be in JSON format.") do |file|
          options.deployment_json = file
      end
      opts.on("-T", "--time [TIME]", Time, "Extract all logs at given time plus 60 seconds (unless -w is specified to override the default window size)") do |time|
        options.time = time
        puts "Time is: '#{time}' of class #{time.class}"
      end
      opts.on("-e", "--environments [ENVS]", Array,
        "The environments where to perform the search. Entries are comma separated.") do |env|
          options.environments = env
      end
      opts.on("-l", "--localities [LOCALITIES]", Array,
        "The localities where to perform the search. Entries are comma separated.") do |env|
          options.localities = env
      end
      opts.on("-c", "--components [COMPONENTS]", Array,
        "The components where to perform the search. Entries are comma separated.") do |env|
          options.components = env
      end
      opts.on("-h", "--hosts [HOSTS]", Array,
        "The components where to perform the search. Entries are comma separated.") do |env|
          options.hosts = env
      end

      opts.on("-k", "--private-key [FILE]",
        "The path to your private key file. If not specified, it defaults to $PRIVATE_KEY.") do |f|
          options.keyfile = f
      end

      opts.on("-d", "--[no-]defaults", "Automatically accepts default values passed via command line arguments.", "Default is not to accept defaults automatically.") do |d|
        options.accept_defaults = d
      end

      opts.on("-v", "--[no-]verbose", "Run verbosely.", "Default is not verbose") do |v|
        options.verbose = v
      end

      opts.on("--log-server [HOST:PORT]", "Host where log server is running.", "Default is localhost:12201") do |h|
        options.log_server = h
      end
      
      opts.on("-w", "--timewindow [w]", Integer, "Number of seconds after the specified time (see -T) to extend the log extraction.", "Default is 60 seconds.") do |n|
         options.timewindow = n
      end
      
      opts.on("-p", "--concurrent-connections [p]", Integer, "Number of concurrent connections to remote servers to fetch log data.", "Default is 5 connections.") do |n|
         options.concurrent_connections = n
      end

      opts.on("-t", "--tokens [TOKENS]", Array,
        "The tokens to match for on each log line. Each token must appear in the log line for the log to be extracted. Entries are comma separated.") do | t |
          options.tokens = t
      end

      opts.separator ""

      opts.on("--show", "Shows available deployments") do
        options.show = true
      end

      opts.separator ""
      opts.separator "Common options:"

      # No argument, shows at tail.  This will print an options summary.
      # Try it and see!
      opts.on_tail("--help", "Show this message") do
        puts opts
        exit
      end
      # Another typical switch to print the version.
      opts.on_tail("--version", "Show version") do
        puts Version.value
        exit
      end
    end

    begin
      opts.parse!(args)
      validate(opts, options)
      @@options = options
      def @@options.to_hash
        self.marshal_dump
      end
      def @@options.update_from_hash hash
        self.marshal_load hash
      end
      @@options
    rescue => e
      puts
      puts "Error: #{e.message}"
      puts
      puts opts
      exit
    end
  end 

  private 

  def self.get_sanitised_keys map
    map.keys.uniq.collect { | k | k.to_s }
  end

  def self.validate(opts, options)
    messages = []
    if(options.deployment_json.nil?)
      messages << "You must specify -f option"
    else
      begin
        options.deployment_json = File.open(options.deployment_json) { | f | f.read }
      rescue => e
        messages << "File '#{options.deployment_json}' can not be read! (#{e.message})"
      end
    end
    unless options.timewindow.to_i  > 0
      messages << "You must specify a positive number for -w"
    end
    unless options.concurrent_connections.to_i  > 0
      messages << "You must specify a positive number for -p"
    end
    if messages.length() > 0
      puts "Errors:"
      puts
      messages.each do |m|
        puts "***  #{m}"
      end
      puts opts
      exit
    end
  end
end 

