require File.join(File.dirname(__FILE__), 'log_fetcher.rb')

class FetcherController
  def fetch options, selections
    @fetchers = build_log_fetchers(options, selections)
    start_fetchers
  end
  
  def build_log_fetchers options, hosts_selection
    fetchers = []
    hosts_selection.keys.each do | host |
      hosts_selection[host].each do | host_data | 
        fetchers << LogFetcher.new(options, host_data)
      end
    end
    fetchers
  end
  
  def start_fetchers
    raise "AAAAAAAAAAAAAA"
  end
  
end
