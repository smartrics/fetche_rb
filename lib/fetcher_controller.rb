require File.join(File.dirname(__FILE__), 'log_fetcher.rb')

class FetcherController
  def fetch options, selections, progress_listener
    @fetchers = build_log_fetchers(options, selections, progress_listener)
    start_fetchers 
    wait_for_fetchers_completion
  end

  private

  def start_fetchers 
    return if @fetchers.nil?
    @fetchers.each do | f |
      f.start
    end
  end

  def wait_for_fetchers_completion
    return if @fetchers.nil?
    @fetchers.each do | f |
      f.wait_completion
    end
  end

  def build_log_fetchers options, hosts_selection, progress_listener
    fetchers = []
    hosts_selection.keys.each do | host |
      hosts_selection[host].each do | host_data |
        fetchers << LogFetcher.new(options, host_data, progress_listener)
      end
    end
    fetchers
  end

end
