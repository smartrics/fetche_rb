require File.join(File.dirname(__FILE__), 'helper.rb')
require File.join(File.dirname(__FILE__), '../lib/fetcher_command.rb')

describe FetcherCommand do
  context "when initializing" do
    it "should fail if :log_file is missing" do
      lambda { FetcherCommand.new :log_file => nil, :datetime_mask => "2011-02-0[12]" }.should raise_error(":log_file is required")
    end
    it "should fail if :time_mask is missing" do
      lambda { FetcherCommand.new :log_file => "/some/path", :datetime_mask => nil }.should raise_error(":datetime_mask is required")
    end
  end
  context "when building a command" do
    it "should default :be_nice to true" do
      FetcherCommand.new(:log_file => "/path", :datetime_mask => "2011").command.should == "nice grep -E -e '2011' /path"
    end
    it "should use :be_nice to prepend grep with nice" do
      FetcherCommand.new(:log_file => "/path", :datetime_mask => "2011", :be_nice => false).command.should == "grep -E -e '2011' /path"
    end
    it "should use :be_nice to prepend multiple greps with nice" do
      FetcherCommand.new(:log_file => "/path", :datetime_mask => "2011", :be_nice => true, :tokens => ["xyz"]).command.should == "nice grep -E -e '2011' /path | nice grep -E -e 'xyz'"
    end
    it "should use :tokens to append multiple greps with the specified tokens" do
      FetcherCommand.new(:log_file => "/path", :datetime_mask => "2011", :be_nice => false, :tokens => ["xyz", "abc"]).command.should == "grep -E -e '2011' /path | grep -E -e 'xyz' | grep -E -e 'abc'"
    end
  end
end