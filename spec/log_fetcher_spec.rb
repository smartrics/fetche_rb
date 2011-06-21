require 'ostruct'
require File.join(File.dirname(__FILE__), 'helper.rb')
require File.join(File.dirname(__FILE__), '../lib/log_fetcher.rb')

describe LogFetcher do

  before(:each) do
    @basic_context = {"host" => "host1", "file" => "file.log.#D", "username" => "username1", "logs_dir" => "var/logs"}
    @options = OpenStruct.new
    @options.time = Time.utc(2011,6,14,17,52,11) 
    @options.timewindow = 78 #seconds
    @fetcher = LogFetcher.new @options, @basic_context
  end

  context "when initialized" do

    it "should create a context with the deployment data" do
      @fetcher.context["host"].should == "host1"
      @fetcher.context["username"].should == "username1"
      @fetcher.context["logs_dir"].should == "var/logs"
      @fetcher.context["file"].should == "file.log.#D"
    end

    it "should create an immutable context" do
      lambda { @fetcher.context["host"] = "someotherhost" }.should  raise_exception(RuntimeError)
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
      @mock_connection = mock("connection")
      Connection.should_receive(:new).and_return(@mock_connection)
      @fetcher = LogFetcher.new @options, @basic_context
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
  
  
end