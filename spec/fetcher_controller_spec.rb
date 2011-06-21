require 'ostruct'
require File.join(File.dirname(__FILE__), 'helper.rb')
require File.join(File.dirname(__FILE__), '../lib/fetcher_controller.rb')

describe FetcherController do
  before(:each) do
    @controller = FetcherController.new
  end

  describe "when building the log fetchers," do
    before(:each) do
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
    end
    
    describe "in normal conditions, " do
      before(:each) do
        mock_log_fetcher = mock("log_fetcher")
        LogFetcher.should_receive(:new).exactly(3).times.and_return(mock_log_fetcher)
      end
      
      it "should build a fetcher for each selected deployment" do
        list = @controller.build_log_fetchers(@empty_options, @selection)
        list.length.should be_equal(3)
      end

    end
  end
end