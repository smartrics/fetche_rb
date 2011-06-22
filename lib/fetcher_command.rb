class FetcherCommand
  
  def initialize args_map
    @log_file = args_map[:log_file]
    raise ":log_file is required" if @log_file.nil?
    @datetime_mask = args_map[:datetime_mask]
    raise ":datetime_mask is required" if @datetime_mask.nil?
    @tokens = args_map[:tokens]
    @tokens = [] if @tokens.nil?
    @be_nice = args_map[:be_nice]
    @be_nice = true if @be_nice.nil?
  end
  
  def command
    niced_grep = nicer("grep -E")
    c = "#{niced_grep} -e '#{@datetime_mask}' #{@log_file}"
    @tokens.each { | t | c << " | #{niced_grep} -e '#{t}'" }
    c
  end
  
  private 
  
  def nicer cmd
    return cmd unless @be_nice
    return "nice #{cmd}"
  end
  
end