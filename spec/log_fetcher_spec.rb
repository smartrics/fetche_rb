require 'ostruct'
require File.join(File.dirname(__FILE__), 'helper.rb')
require File.join(File.dirname(__FILE__), '../lib/log_fetcher.rb')

describe LogFetcher do

  before(:each) do
    @basic_context = {"host" => "host1", "file" => "file.log.%Y-%m-%d", "username" => "username1", "logs_dir" => "var/logs"}
    @options = OpenStruct.new
    @options.time = Time.utc(2011,6,14,17,52,11)
    @options.timewindow = 78 #seconds
    @mock_progress_listener = double("mock_progress_listener")
    @mock_progress_listener.stub(:puts)
    @mock_connection = mock("mock_connection")
    Connection.stub(:new).and_return(@mock_connection)
    @fetcher = LogFetcher.new @options, @basic_context, @mock_progress_listener
  end

  context "when initialized" do

    it "should create a connection object to delegate remote commands to" do
      Connection.should_receive(:new).with(hash_including(
        :user => @basic_context["username"], 
        :host => @basic_context["host"])).and_return(@mock_connection)
      @fetcher = LogFetcher.new @options, @basic_context, @mock_progress_listener
    end

    it "should create a context with the deployment data" do
      @fetcher.context["host"].should == "host1"
      @fetcher.context["username"].should == "username1"
      @fetcher.context["logs_dir"].should == "var/logs"
      @fetcher.context["file"].should == "file.log.%Y-%m-%d"
    end

    it "should create an immutable context" do
      lambda { @fetcher.context["host"] = "someotherhost" }.should raise_exception(RuntimeError)
    end

    it "should raise exception if no option is passed in" do
      lambda do
        LogFetcher.new nil, @basic_context, @mock_progress_listener
      end.should raise_exception("options are mandatory")
    end

    it "should raise exception if no timewindow option is passed in" do
      @options.timewindow = nil
      lambda do
        LogFetcher.new @options, @basic_context, @mock_progress_listener
      end.should raise_exception("timewindow option is mandatory")
    end

    it "should raise exception if no time option is passed in" do
      @options.time = nil
      lambda do
        LogFetcher.new @options, @basic_context, @mock_progress_listener
      end.should raise_exception("time option is mandatory")
    end

    it "should raise exception if no file is selected" do
      context = @basic_context.dup #basic_context gets frozen !
      context["file"] = nil
      lambda do
        LogFetcher.new @options, context, @mock_progress_listener
      end.should raise_exception("file is mandatory")
    end

    it "should raise exception if no host is selected" do
      context = @basic_context.dup #basic_context gets frozen !
      context["host"] = nil
      lambda do
        LogFetcher.new @options, context, @mock_progress_listener
      end.should raise_exception("host is mandatory")
    end

    it "should raise exception if no username is selected" do
      context = @basic_context.dup #basic_context gets frozen !
      context["username"] = nil
      lambda do
        LogFetcher.new @options, context, @mock_progress_listener
      end.should raise_exception("username is mandatory")
    end

    it "should build datetime_mask as a regular expression matching all date/time stamps between a start time and a time window length" do
      time = @options.time
      time_win = @options.timewindow
      /#{@fetcher.datetime_mask}/.should =~ time.to_s
      /#{@fetcher.datetime_mask}/.should =~ (time + 10).to_s
      /#{@fetcher.datetime_mask}/.should =~ "#{(time + 50).to_s}:567 plus something else"
      /#{@fetcher.datetime_mask}/.should =~ (time + time_win).to_s
      /#{@fetcher.datetime_mask}/.should_not =~ (time - 12).to_s
      /#{@fetcher.datetime_mask}/.should_not =~ (time + time_win + 33).to_s
    end

  end

  context "when calculating time difference with a host" do
    before(:each) do
      @num_of_sec_in_two_and_half_h = 9000
    end

    it "should return the difference in seconds with a host if positive" do
      @mock_connection.should_receive(:execute).with(@basic_context, 'date +%::z').and_return("+02:30:00")
      result = @fetcher.utc_time_adjustment("host")
      result.should == @num_of_sec_in_two_and_half_h
    end

    it "should return the difference in seconds with a host if negative" do
      @mock_connection.should_receive(:execute).with(@basic_context, 'date +%::z').and_return("-02:30:00")
      result = @fetcher.utc_time_adjustment("host")
      result.should == -@num_of_sec_in_two_and_half_h
    end

  end

  context "when starting to fecth" do
    before(:each) do
      @mock_worker = mock("worker-thread")
    end
    after(:each) do
    end

    it "should create and execute a thread that does the real job" do
      Thread.should_receive(:new).and_return(@mock_worker)
      @fetcher.start { | progress_listener, data | data }
    end

  end

  context "when worker threads start" do
    it "should start a thread once" do
      @mock_connection.stub(:execute)
      @fetcher.start { | progress_listener, data | data }
      lambda { @fetcher.start { | progress_listener, data | data } }.should raise_error(RuntimeError)
    end

    it "should start a thread that builds the command to execute to the remote host" do
      @mock_connection.should_receive(:execute).with("nice grep -E -e '2011-06-14 17:5[23]+' var/logs/file.log.2011-06-14", @mock_progress_listener)
      @fetcher.start { | progress_listener, data | data }
    end
    
    context "and performs execution" do
      before(:each) do
        @mock_fetcher_command = mock("fetcher_command")
        FetcherCommand.stub(:new).and_return(@mock_fetcher_command)
        @mock_fetcher_command.stub(:command).and_return("command")
      end

      it "should start a thread that delegates execution to underlying connection" do
        @mock_progress_listener.should_receive(:puts).with("Fetcher[22] started. host:'host1', user:'username1', logfile:'var/logs/file.log.%Y-%m-%d', command:'command'")
        @mock_connection.should_receive(:execute).with("command", @mock_progress_listener)
        @fetcher.start { | progress_listener, data | data }
      end

      it "should yield to the passed block each line retrieved from the underlying connection" do
        @mock_connection.stub(:execute).with("command", @mock_progress_listener).and_yield("line1\nline2\nline3");
        result = @fetcher.start do | progress_listener, log_line |
          log_line.should =~ /line[123]?\n?/
        end
      end

      it "should raise an exception if no block given to process data" do
        @mock_connection.stub(:execute).with("command", @mock_progress_listener);
        lambda { @fetcher.start }.should raise_error(RuntimeError)
      end

      it "should raise an exception if given block has arity different than two" do
        @mock_connection.stub(:execute).with("command", @mock_progress_listener);
        lambda { @fetcher.start {} }.should raise_error(RuntimeError)
      end
    end

    after(:each) do
      @fetcher.wait_completion
    end
  end
end