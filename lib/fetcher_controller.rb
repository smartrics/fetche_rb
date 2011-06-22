require File.join(File.dirname(__FILE__), 'log_fetcher.rb')

class FetcherController
  def fetch options, selections, &progress_listener
    @fetchers = build_log_fetchers(options, selections)
    register_progress_listener &progress_listener if block_given?
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

  def register_progress_listener &progress_listener
    return if @fetchers.nil?
    @fetchers.each do | f |
      f.progress_listener = Proc.new(progress_listener)
    end
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

end
