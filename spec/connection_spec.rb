require 'ostruct'
require File.join(File.dirname(__FILE__), 'helper.rb')
require File.join(File.dirname(__FILE__), '../lib/log_fetcher.rb')

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
    
  end

end