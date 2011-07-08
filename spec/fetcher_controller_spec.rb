require 'ostruct'
require File.join(File.dirname(__FILE__), 'helper.rb')
require File.join(File.dirname(__FILE__), '../lib/fetcher_controller.rb')

describe FetcherController do
  before(:each) do
    @controller = FetcherController.new
    @empty_selection = {}
    @selection = [
      {"name"=>"facility-1", "host" => "host1", "username"=>"username1", "logs_dir"=>"facility-1/logs", "file"=>"facility.1.log.%Y-%m-%d"},
      {"name"=>"facility-2a", "host" => "host2", "username"=>"username1", "logs_dir"=>"facility-2a/logs", "file"=>"facility.2a.log.%Y-%m-%d"},
      {"name"=>"facility-2b", "host" => "host2", "username"=>"username1", "logs_dir"=>"facility-2b/logs", "file"=>"facility.2b.log.%Y-%m-%d"}
    ]
    @empty_options = OpenStruct.new
    @default_options = OpenStruct.new
    @default_options.tokens = [ 'token1', 'token2' ]
    @mock_progress_listener = mock("mock_progress_listener")
    @mock_log_fetchers = []
    @mock_log_fetchers << mock("log_fetcher_1", :id=>1, :sent => 1, :to_send => 10)
    @mock_log_fetchers << mock("log_fetcher_2", :id=>2, :sent => 2, :to_send => 20)
    @mock_log_fetchers << mock("log_fetcher_3", :id=>3, :sent => 3, :to_send => 30)
    @mock_log_fetchers.each do | f |
      f.stub(:context).and_return({"name" => "some", "host" => "localhost"})
      f.stub(:progress_listener).and_return(@mock_progress_listener)
    end
  end

  context "when initializing the fetchers" do
    before(:each) do
      @mock_log_fetchers.each { | f | f.stub(:start) }
      @mock_log_fetchers.each { | f | f.stub(:wait_completion) }
      @mock_progress_listener.stub(:puts)
    end
    it "should build a fetcher for each selected deployment" do
      LogFetcher.should_receive(:new).with(@empty_options, @selection[0], @mock_progress_listener).and_return(@mock_log_fetchers[0])
      LogFetcher.should_receive(:new).with(@empty_options, @selection[1], @mock_progress_listener).and_return(@mock_log_fetchers[1])
      LogFetcher.should_receive(:new).with(@empty_options, @selection[2], @mock_progress_listener).and_return(@mock_log_fetchers[2])

      list = @controller.fetch(@empty_options, @selection, @mock_progress_listener)
      list.length.should be_equal(3)
    end
  end

  context "when managing the fetchers" do
    before(:each) do
      LogFetcher.stub(:new).exactly(3).times.and_return(@mock_log_fetchers[0], @mock_log_fetchers[1], @mock_log_fetchers[2])
      @mock_progress_listener.stub(:puts)
    end

    it "should start all fetchers" do
      LogClient.should_receive(:new).exactly(3).times.with @empty_options, "some", "localhost"
      @mock_log_fetchers.each { | f | f.should_receive(:start) }
      @mock_log_fetchers.each { | f | f.stub(:wait_completion) }
      @controller.fetch(@empty_options, @selection, @mock_progress_listener)
    end

    it "should wait all fetchers to complete" do
      @mock_log_fetchers.each { | f | f.stub(:start) }
      @mock_log_fetchers.each { | f | f.should_receive(:wait_completion) }
      @mock_progress_listener.should_receive(:puts).with("Fetcher[1] report: 1/10 messages sent")
      @mock_progress_listener.should_receive(:puts).with("Fetcher[2] report: 2/20 messages sent")
      @mock_progress_listener.should_receive(:puts).with("Fetcher[3] report: 3/30 messages sent")
      @controller.fetch(@empty_options, @selection, @mock_progress_listener)
    end
  end

end
