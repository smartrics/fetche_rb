require File.join(File.dirname(__FILE__), 'fetcher_controller.rb')

class FetcherUi
  def initialize options
    @controller = FetcherController.new
    @options = options
    @deployment = deployment = Deployment.new(options.deployment_json)
    @selected_env = []
    @selected_loc = []
    @selected_comp = []
    @selected_hosts = []
    build_menu
  end

  def selected_environments
    @selected_env
  end

  def selected_localities
    @selected_loc
  end

  def selected_components
    @selected_comp
  end

  def selected_hosts
    @selected_hosts
  end

  def loop
    return if show_and_exit?
    cont = true
    @current_menu = 0;
    next_menu = @menus[@current_menu]
    begin
      if(@options.accept_defaults)
        set_defaults
      else
        while(cont)
          next_menu = process(next_menu)
          cont = !next_menu.nil?
        end
      end
      show_selections()
      dispatch_selections()
    rescue => e
      print_stack_trace "Quitting", e
    end
  end

  private 
  
  def menu(name, options, defaults, with_back = true, with_all = true)
    puts "options: #{options}, def: #{defaults}"
    selections = []
    puts ""
    puts name
    while true do
      pos = 0
      some_defaulted = false
      options.each do  | e |
        selected = ""
        if !defaults.find_index(e.to_s).nil?
          selected = "*"
          some_defaulted = true
        end
        puts "  #{pos}. #{selected}#{e.to_s}"
        pos = pos + 1
      end
      puts
      puts "  No selection available\n" if pos == 0
      puts "  a. all" if with_all && pos > 0
      puts "  d. defaults" if some_defaulted
      puts "  b. back" if with_back
      puts "  q. quit"
      print "> "
      c = get_input
      if is_input_valid?(c)
        return :quit if c[0] == 'q' 
        return :back if c[0] == 'b' && with_back
        return (selections + options) if c[0]=='a' && with_all
        return (selections + (defaults & options)) if c[0]=='d' && some_defaulted
        c.each do | x |
          if(x =~ /\d+/)
            ci = x.to_i
            selections << options[ci] if ci >=0 && ci < options.length
          end
        end
        return selections.flatten if selections.length > 0
      end
      puts "invalid option '#{c}'"
      puts ""
    end
    selections
  end

  def is_input_valid?(ary)
    is_non_empty_array = ary.kind_of?(Array) && ary.length > 0
    is_command = ([ary[0]] && ["q", "a", "b", "d"]).length > 0
    is_all_digits = ary.reject { | el | !(el =~ /\d+/).nil? }.length == 0
  
    is_non_empty_array && (is_command || (!is_command && is_all_digits))
    
  end
  
  def process menu
    res = menu.call

    if(res==:quit)
      raise "selected quit"
    end
    if(res==:back)
      @current_menu = @current_menu - 1 if @current_menu > 0
      return @menus[@current_menu]
    end
    @current_menu = @current_menu + 1
    return nil if @current_menu == @menus.length
    @menus[@current_menu]
  end

  def get_input
    line = STDIN.readline
    line.split(' ').uniq.reject { | x | x == ' ' }
  end

  def show_selections
    puts "Selected Environment:"
    puts "   #{selected_environments()}"
    puts ""
    puts "Selected Localities:"
    puts "   #{selected_localities()}"
    puts ""
    puts "Selected Components:"
    puts "   #{selected_components()}"
    puts ""
    puts "Selected Hosts:"
    puts "   #{selected_hosts()}"
    puts ""
  end

  def show_deployment verbose
    @deployment.show :verbose => verbose
  end

  def build_menu
    @menus = [
      Proc.new do
        begin
          res = menu('Select environment', @deployment.environments('env' => @selected_env).keys, @options.environments, false, false)
          @selected_env = res.uniq if res.kind_of?(Array)
          res
        rescue => e
          print_stack_trace "Exception when selecting environment", e
          raise e
        end
      end,
      Proc.new do
        begin
          res = menu('Select locality', @deployment.localities('env' => @selected_env).keys, @options.localities, true, false)
          @selected_loc = res.uniq if res.kind_of?(Array)
          res
        rescue => e
          print_stack_trace "Exception when selecting locality", e
          raise e
        end
      end,
      Proc.new do
        begin
          puts "Going to fetch components: @selected_env: #{@selected_env}, @selected_loc: #{@selected_loc}"
          res = menu("Select components", @deployment.components('env' => @selected_env, 'loc' => @selected_loc).keys, @options.components)
          @selected_comp = res.uniq if res.kind_of?(Array)
          res
        rescue => e
          print_stack_trace "Exception when selecting components", e
          raise e
        end
      end,
      Proc.new do
        begin
          res = menu('Select hosts', @deployment.hosts('env' => @selected_env, 'loc' => @selected_loc, 'comp' => @selected_comp).keys.to_a, @options.hosts)
          @selected_hosts = res.uniq if res.kind_of?(Array)
          res
        rescue => e
          print_stack_trace "Exception when selecting hosts", e
          raise e
        end
      end
    ]

  end
  
  def set_defaults
    @selected_env = @deployment.environments.keys 
    @selected_env = @selected_env & @options.environments unless @options.environments.empty?
    @selected_loc = @deployment.localities('env' => @selected_env).keys 
    @selected_loc = @selected_loc & @options.localities unless @options.localities.empty?
    @selected_comp = @deployment.components('env' => @selected_env, 'loc' => @selected_loc).keys
    @selected_comp = @selected_comp & @options.components unless @options.components.empty?
    @selected_hosts = @deployment.hosts('env' => @selected_env, 'loc' => @selected_loc, 'comp' => @selected_comp).keys
    @selected_hosts = @selected_hosts & @options.hosts unless @options.hosts.empty?
  end
  
  def show_and_exit?
    if(@options.show)
      method = :keys
      if(@options.verbose)
        method = :to_s
      end
      show method
      return true
    end
    return false
  end

  def show method
    puts '--- environments'
    puts @deployment.environments.send(method)
    puts ''
    puts '--- localities'
    puts @deployment.localities.send(method)
    puts ''
    puts '--- components'
    puts @deployment.components.send(method)
    puts ''
    puts '--- hosts'
    puts @deployment.hosts.send(method)
    puts ''
  end
  
  def dispatch_selections
    hosts = @deployment.hosts('env' => @selected_env, 'loc' => @selected_loc, 'comp' => @selected_comp, 'hosts' => @selected_hosts)
    @controller.fetch @options, hosts, $stdout
  end

  def print_stack_trace(message, e) 
    puts "#{message}: #{e.message}"
    puts "    #{e.backtrace.join("\n    ")}"
  end

end
