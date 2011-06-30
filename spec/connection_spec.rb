require 'ostruct'
require File.join(File.dirname(__FILE__), 'helper.rb')
require File.join(File.dirname(__FILE__), '../lib/log_fetcher.rb')
require File.join(File.dirname(__FILE__), '../lib/connection.rb')

describe Connection do

  before(:each) do
    @args = { :user => "user", :host => 'host', :verbose => true, :key => '/path/to/pk', :password => '#+-*$@7^5'}
  end

  context "when initialized" do

    it "should mandate user" do
      @args[:user] = nil
      lambda { Connection.new @args }.should raise_error("user is mandatory")
    end

    it "should mandate host" do
      @args[:host] = nil
      lambda { Connection.new @args }.should raise_error("host is mandatory")
    end
    
    it "should mandate key or password" do
      @args[:key] = nil
      @args[:password] = nil
      lambda { Connection.new @args }.should raise_error("key or password are mandatory")
    end
    
    it "should get key from environment if not available" do
      @args[:key] = nil
      oldkey = ENV['PRIVATE_KEY']
      ENV['PRIVATE_KEY'] = '/path'
      c = Connection.new @args
      c.key.should == '/path'
      ENV['PRIVATE_KEY'] = oldkey
    end
    
    it "should default verbose to warning" do
      @args[:verbose] = nil
      c = Connection.new @args 
      c.verbose().should == :warning
    end
    
    it "should set verbose to debug when passed verbosity" do
      @args[:verbose] = true
      c = Connection.new @args 
      c.verbose().should == :debug
    end

    context "when Net::SSH is mocked out" do
      before(:each) do
        @net_ssh_mock = mock("net_ssh_mock")
        @ssh_session_mock = mock("ssh_session_mock")
        @ssh_channel_mock = mock("ssh_channel_mock")
      end
      
      it "should yield the passed block with the input data" do
        c = Connection.new @args 
        progress_listener = $stderr
        Net::SSH.should_receive(:start).with(@args[:host], @args[:user], hash_including(:logger => progress_listener)).and_yield(@ssh_session_mock)
        @ssh_session_mock.should_receive(:open_channel).and_yield(@ssh_channel_mock)
        stub = @ssh_channel_mock.should_receive(:on_data)
        stub.and_yield(@ssh_channel_mock, "some")
        stub.and_yield(@ssh_channel_mock, "data")
        @ssh_channel_mock.should_receive(:exec).with("command")
        lines = []
        c.execute "command", progress_listener do | line | 
          lines << line
        end
        lines[0].should == "some"
        lines[1].should == "data"
      end
    end
        
  end

end