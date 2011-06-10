class FetcherUi

  def initialize deployment
    @deployment = deployment
    @selected_env = []
    @selected_loc = []
    @selected_comp = []
    @selected_hosts = []
      
    @menus = [
      Proc.new do 
        begin
          res = menu('Select environment', @deployment.environments.keys.to_a, false, false)
          @selected_env = res if res.kind_of?(Array)
          res
        rescue => e
          p e
          raise e
        end
      end,
      Proc.new do
        begin
          res = menu('Select locality', @deployment.localities(:env => @selected_env).keys.to_a, true, false)
          @selected_loc = res if res.kind_of?(Array)
          res
        rescue => e
          p e
          raise e
        end
      end,
      Proc.new do
        begin
          res = menu("Select components", @deployment.components(:env => @selected_env, :loc => @selected_loc).keys.to_a)
          @selected_comp = res if res.kind_of?(Array)
          res
        rescue => e
          p e
          raise e
        end
      end,
      Proc.new do
        begin
          res = menu('Select hosts', @deployment.hosts(:env => @selected_env, :loc => @selected_loc, :comp => @selected_comp).keys.to_a)
          @selected_hosts = res if res.kind_of?(Array)
          res
        rescue => e
          p e
          raise e
        end
      end
    ]
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
    
  def menu(name, options, with_back = true, with_all = true)
    selections = []
    puts ""
    puts name
    while true do
      pos = 0  
      options.each do  | e |
        puts "  #{pos}. #{e.to_s}"
        pos = pos + 1
      end
      puts
      puts "  No selection available\n" if pos == 0
      puts "  a. all" if with_all && pos > 0
      puts "  b. back" if with_back
      puts "  q. quit"
      print "> "
      c = get_input
      return :quit if c[0]=='q' && c.length == 1
      return :back if c[0]=='b' && c.length == 1 && with_back
      return selections + options if c=='a' && c.length == 1 && with_all
      c.each do | x | 
        ci = x.to_i
        selections << options[ci] if ci >=0 && ci < options.length
      end 
      return selections if selections.length > 0
      puts "invalid option '#{c}'"
      puts ""
    end
    selections
  end

  def loop
    cont = true
    @current_menu = 0;
    next_menu = @menus[@current_menu]
    begin
      while(cont)
        next_menu = process(next_menu)
        cont = !next_menu.nil?
      end
      p "Exiting menu loop..."
    rescue => e
      p "Quitting: #{e.message}" 
    end
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
    puts f.selected_environments()
    puts ""
    puts "Selected Localities:"
    puts f.selected_localities()
    puts ""
    puts "Selected Components:"
    puts f.selected_components()
    puts ""
    puts "Selected Hosts:"
    puts f.selected_hosts()
    puts ""
  end
  
  def show_deployment verbose
    @deployment.show :verbose => verbose
  end
  
end
