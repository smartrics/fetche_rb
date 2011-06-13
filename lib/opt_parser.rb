require File.dirname(__FILE__) + '/version.rb'
require 'optparse'
require 'optparse/time'
require 'ostruct'
require 'pp'

class OptParser
  
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
    options.timewindow = 5
    options.tokens = []
    options.verbose = false
    options.deployment_json = nil
    options.show = false

    opts = OptionParser.new do |opts|
      opts.banner = "Usage: fetcher.rb [options]"

      opts.separator ""
      opts.separator "Specific options:"

      opts.on("-f", "--deployment-file FILE", 
        "The file containing the deployment database. The file is expected to be in JSON format.") do |file|
          options.deployment_json = file
      end
      opts.on("-e", "--environments [ENVS]", Array,
        "The environments where to perform the search. Entries are comma separated.") do |env|
          options.environments = env
      end
      opts.on("-l", "--localities [LOCALITIES]", Array,
        "The localities where to perform the search. Entries are comma separated.") do |env|
          options.environments = env
      end
      opts.on("-c", "--components [COMPONENTS]", Array,
        "The components where to perform the search. Entries are comma separated.") do |env|
          options.environments = env
      end
      opts.on("-h", "--hosts [HOSTS]", Array,
        "The components where to perform the search. Entries are comma separated.") do |env|
          options.environments = env
      end

      opts.on("-d", "--[no-]defaults", "Automatically accepts default values passed via command line arguments.", "Default is not to accept defaults automatically.") do |d|
        options.accept_defaults = d
      end

      opts.on("-v", "--[no-]verbose", "Run verbosely.", "Default is not verbose") do |v|
        options.verbose = v
      end

      opts.on("-T", "--time TIME", Time, "Extract logs at given time (plus/minus the time window specified with -w)") do |time|
        options.time = time
        puts "Time is: '#{time}' of class #{time.class}"
      end

      opts.on("-w", "--timewindow [S]", Integer, "Number of seconds before and after the specified time (see -T) to extend the log extraction.", "Default is 5.") do |n|
         options.delay = n
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
      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end
      # Another typical switch to print the version.
      opts.on_tail("--version", "Show version") do
        puts Version.value
        exit
      end
    end

    opts.parse!(args)
    validate(opts, options)
    options
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
    if options.time.nil?
      messages << "You must specify -T option"
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

