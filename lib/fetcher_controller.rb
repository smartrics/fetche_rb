require File.join(File.dirname(__FILE__), 'log_fetcher.rb')
require File.join(File.dirname(__FILE__), 'log_client.rb')

class FetcherController
  def fetch options, selections, progress_listener
    grouped_selections = groupby_hosts(selections)
    @fetchers = build_log_fetchers(options, grouped_selections, progress_listener)
    start_fetchers options
    wait_for_fetchers_completion
  end

  private

  def start_fetchers options 
    return if @fetchers.nil?
    @fetchers.each do | f |
      log_client = LogClient.new options, f.context["name"],  f.context["host"]
      f.start do | progress_listener, log_line | 
        f.to_send = f.to_send + 1 
        result_map = log_client.notify(log_line)
        progress_listener.puts "Fetcher[#{f.id}] last notification status:'#{result_map["sent"]}'. line[0..70]:'#{log_line[0, 70]}...'" #if options.verbose
        f.sent = f.sent + 1 if result_map["sent"]
      end
    end
  end

  def wait_for_fetchers_completion
    return if @fetchers.nil?
    @fetchers.each do | f |
      f.wait_completion
    end
    @fetchers.each do | f |
      f.progress_listener.puts "Fetcher[#{f.id}] report: #{f.sent}/#{f.to_send} messages sent"
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

  def groupby_hosts selections
    grouped_selections = {}
    selections.each do | sel |
      host = sel["host"]
      grouped_selections[host] = [] if grouped_selections[host].nil?
      grouped_selections[host] << sel
    end
    grouped_selections
  end
end
