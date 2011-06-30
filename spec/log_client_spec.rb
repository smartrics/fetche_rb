require 'ostruct'
require 'gelf'
require File.join(File.dirname(__FILE__), 'helper.rb')
require File.join(File.dirname(__FILE__), '../lib/log_client.rb')

#"2011-07-12 14:23:23.586 <something in the area> [12345] bablabla"

describe LogClient do
  before(:each) do
    @mock_notifier = mock("mock-notifier")
    @component = "server"
    @host = "galileo"
    @options = OpenStruct.new
    @options.log_server = "some.host:12345"
  end
  
  context "when initialising" do

    it "should initialize the underlying gelf notifier" do
      defaults = {'host' => @host, 'facility' => @component }
      GELF::Notifier.should_receive(:new).with("some.host", 12345, 'LAN', defaults).and_return(@mock_notifier)
      @log_client = LogClient.new @options, @component, @host
      @log_client.host.should == @host
      @log_client.component.should == @component
      @log_client.log_host.should == "some.host"
      @log_client.log_port.should == 12345
    end

  end
  
  context "when notifying the remote log server" do
    before(:each) do
      GELF::Notifier.stub(:new).and_return(@mock_notifier)
      @timestamp_s = '2011-06-28 17:05:27,713'
      @timestamp = Time.utc 2011, 6, 28, 17, 5, 27, 713
      @process = 'main'
      @level = 'INFO '
      @clazz = 'some.class.producing.the.Log'
      @message = 'the log message'
      @fields = '[deal-id=1234567890, a-field=98t39 session-id=jkfhgshkdsjghk]'
      @log_client = LogClient.new @options, @component, @host
    end
    
    it "should parse the log line and send its component to the notifier" do
      log_line = "#{@timestamp_s} <#{@process}> [#{@level}  ] [#{@clazz}] #{@message}"
      # not checking timestamp as equality is tricky
      @mock_notifier.should_receive(:notify).with(hash_including(
        'host' => @host,
        'facility' => @component,
        #'timestamp' => @timestamp,
        'long_message' => log_line,
        'short_message' => @message,
        'level' => GELF::Levels::INFO,
        '_class' => @clazz,
        '_process' => @process))
      @log_client.notify log_line
    end
    
    it "should parse the short message for any configured additional field" do
      log_line = "#{@timestamp_s} <#{@process}> [#{@level}] [#{@clazz}] #{@message} #{@fields} blabla"
      @mock_notifier.should_receive(:notify).with(hash_including(
        '_deal' => '1234567890',
        '_session' => 'jkfhgshkdsjghk'))
      @log_client.notify log_line
    end
    
    it "should contain the additional field _dup_id with the digest of the logline to avoid duplication" do
      log_line = "#{@timestamp_s} <#{@process}> [#{@level}] [#{@clazz}] #{@message} #{@fields} blabla"
      @mock_notifier.should_receive(:notify).with(hash_including(
        '_dup_id' => Digest::MD5.hexdigest(log_line)
      ))
      @log_client.notify log_line
    end
    
  end
end