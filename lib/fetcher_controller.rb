require File.join(File.dirname(__FILE__), 'log_fetcher.rb')
require File.join(File.dirname(__FILE__), 'log_client.rb')

class FetcherController
  def fetch options, selections, progress_listener
    @fetchers = build_log_fetchers(options, selections, progress_listener)
    start_fetchers options
    wait_for_fetchers_completion
  end

  private

  def start_fetchers options 
    return if @fetchers.nil?
    @fetchers.each do | f |
      log_client = LogClient.new options, f.context["component"],  f.context["host"]
      f.start do | progress_listener, log_line | 
        result = log_client.notify(log_line)
        progress_listener.puts "notifyed line '#{result}': #{line}"
      end
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
