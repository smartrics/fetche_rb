require 'ostruct'
require File.join(File.dirname(__FILE__), 'helper.rb')
require File.join(File.dirname(__FILE__), '../lib/fetcher_controller.rb')

describe FetcherController do
  before(:each) do
    @controller = FetcherController.new
    @empty_selection = {}
    @selection = {
      "host1"=>[
      {"name"=>"facility-1", "username"=>"username1", "logs_dir"=>"facility-1/logs", "file"=>"facility.1.log.#D"}
      ],
      "host2"=>[
      {"name"=>"facility-2a", "username"=>"username1", "logs_dir"=>"facility-2a/logs", "file"=>"facility.2a.log.#D"},
      {"name"=>"facility-2b", "username"=>"username1", "logs_dir"=>"facility-2b/logs", "file"=>"facility.2b.log.#D"}
      ]
    }
    @empty_options = OpenStruct.new
    @default_options = OpenStruct.new
    @default_options.tokens = [ 'token1', 'token2' ]
    @mock_log_fetchers = []
    @mock_log_fetchers << mock("log_fetcher_1")
    @mock_log_fetchers << mock("log_fetcher_2")
    @mock_log_fetchers << mock("log_fetcher_3")
    LogFetcher.stub(:new).exactly(3).times.and_return(@mock_log_fetchers[0], @mock_log_fetchers[1], @mock_log_fetchers[2])
  end

  context "when initializing the fetchers" do
    before(:each) do
      @mock_log_fetchers.each { | f | f.stub(:start) }
      @mock_log_fetchers.each { | f | f.stub(:wait_completion) }
    end
    it "should build a fetcher for each selected deployment" do
      list = @controller.fetch(@empty_options, @selection)
      list.length.should be_equal(3)
    end
  end

  it "should start all fetchers" do
    @mock_log_fetchers.each { | f | f.should_receive(:start) }
    @mock_log_fetchers.each { | f | f.stub(:wait_completion) }
    @controller.fetch(@empty_options, @selection)
  end

  it "should wait all fetchers to complete" do
    @mock_log_fetchers.each { | f | f.stub(:start) }
    @mock_log_fetchers.each { | f | f.should_receive(:wait_completion) }
    @controller.fetch(@empty_options, @selection)
  end

end
