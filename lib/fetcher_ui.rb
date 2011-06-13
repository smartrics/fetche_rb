class FetcherUi
  def initialize options
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
      while(cont)
        next_menu = process(next_menu)
        cont = !next_menu.nil?
      end
      show_selections()
    rescue => e
      p "Quitting: #{e.message}"
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
          @selected_env = res if res.kind_of?(Array)
          @selected_env.uniq!
        rescue => e
          puts "Exception when selecting environment: #{e}"
          puts "    #{e.backtrace.join("\n    ")}"
          raise e
        end
      end,
      Proc.new do
        begin
          res = menu('Select locality', @deployment.localities('env' => @selected_env).keys, @options.localities, true, false)
          @selected_loc = res if res.kind_of?(Array)
          @selected_loc.uniq!
        rescue => e
          puts "Exception when selecting locality: #{e}"
          puts "    #{e.backtrace.join("\n    ")}"
          raise e
        end
      end,
      Proc.new do
        begin
          puts "Going to fetch components: @selected_env: #{@selected_env}, @selected_loc: #{@selected_loc}"
          res = menu("Select components", @deployment.components('env' => @selected_env, 'loc' => @selected_loc).keys, @options.components)
          @selected_comp = res if res.kind_of?(Array)
          res
        rescue => e
          puts "Exception when selecting components: #{e}"
          puts "    #{e.backtrace.join("\n    ")}"
          raise e
        end
      end,
      Proc.new do
        begin
          res = menu('Select hosts', @deployment.hosts('env' => @selected_env, 'loc' => @selected_loc, 'comp' => @selected_comp).keys.to_a, @options.hosts)
          @selected_hosts = res if res.kind_of?(Array)
          res
        rescue => e
          puts "Exception when selecting hosts: #{e}"
          puts "    #{e.backtrace.join("\n    ")}"
          raise e
        end
      end
    ]

  end

  def show_and_exit?
    if(@options.show)
      method = :to_s
      if(options.verbose)
        method = :keys
      end
      show method
      return true
    end
    return false
  end

  def show method
    puts '--- environments'
    puts environments.send_to(method)
    puts ''
    puts '--- localities'
    puts localities.send_to(method)
    puts ''
    puts '--- components'
    puts components.send_to(method)
    puts ''
    puts '--- hosts'
    puts hosts.send_to(method)
    puts ''
  end

end
