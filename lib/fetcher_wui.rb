require File.dirname(__FILE__) + '/deployment_db'
require File.dirname(__FILE__) + '/opt_parser'
require File.dirname(__FILE__) + '/fetcher_controller'
require 'sinatra/base'
require 'erb'
require 'json'
require 'cgi'

# Fetcherb web user interface
class FetcherWui < Sinatra::Base

  set :public, File.dirname(__FILE__) + '/../public'
  set :views, File.dirname(__FILE__) + '/../views'

  get "/" do
    erb :index
  end

  get "/options" do
    content_type :json
    OptParser.options.to_hash.to_json
  end
  
  post "/fetcher" do
    content = request.body.read
    verbose = params["options"][:verbose]
    params["options"][:verbose] = false
    params["options"][:verbose] = true if verbose=="on"
    OptParser.options.update_from_hash params["options"]
    hosts = DeploymentDb.instance.get params["ids"]
    controller = FetcherController.new
    prog_listener = $stdout
    controller.fetch OptParser.options, hosts, prog_listener
  end
  
  post "/deployments" do
    if params[:oper] == "add"
      tags = []
      tags = params[:tags].split(",") unless params[:tags].nil?
      new_data = {
        "name"  => params[:name],
        "host"  => params[:host],
        "username"  => params[:username],
        "logs_dir"  => params[:logs_dir],
        "file"  => params[:file],
        "environment"  => params[:environment],
        "tags"  => tags,
      }
      DeploymentDb.instance.add(new_data)
    end
    if params[:oper] == "del"
      DeploymentDb.instance.del(params[:id])
    end
  end

  get "/deployments" do
    begin
      page = 1
      total = 1
      sidx = params[:sidx] || "name"
      sord = params[:sord] || "desc"
      filters_string = params[:filters] || ""
      filters = filter_functions(filters_string)
      content_type :json
      deployments = DeploymentDb.instance.data.dup
      records = deployments.size
      deployments.delete_if do | depl |
        result = []
        filters.each do | f |
          begin
            result << f.call(depl)
          rescue => e
            puts "[EXC #{e.message}]"
          end
        end
        r = true
        result.each { | fr | r = r && fr }
        !r
      end
      deployments.sort! do | l, r |
        return l[sidx] <=> r[sidx] if sord == "asc"
        r[sidx] <=> l[sidx]
      end
      grid = {"page" => page, "total" => total, "records" => records, "rows" => to_jqgrid_rows(deployments) }
      grid.to_json
    rescue => e
      puts e.backtrace().join("\n")
    end
  end

  def filter_functions string
    return [] if string.empty?
    raw = CGI.unescape(string)
    p = JSON::Parser.new(raw)
    filters = p.parse
    rulesFun = []
    filters["rules"].each do | el |
      rulesFun << Proc.new do | map |
        # the input map is that coming from the deployment
        overall_result = [] # true for each filter that match the attribute to filter
        begin
          src = map[el["field"]] # the attribute to filter
          matcher = el["data"] # the filter data
          all_filters_size = 1
          unless(matcher.nil? || src.nil?)
            if src.kind_of?(Array)
              matched_array = []
              matcher_array = matcher.split(",").collect { | el | el.strip }
              result = []
              matcher_array.each do | regex |
                src.each do | s |
                  r = (s =~ /#{regex}/)
                  result << r
                end
              end
              all_filters_size = matcher_array.size
              overall_result = result.compact
            else
              r = (src =~ /#{matcher}/)
              overall_result << r
            end
          end
        rescue => e
          puts "[EXCEPTION #{e.message}"
          overall_result = []
        end
        overall_result.compact.size == all_filters_size
      end
    end
    rulesFun
  end

  def to_jqgrid_rows(deployments)
    result = []
    #'Name','Host', 'User', 'Dir','File','Tags'
    deployments.each do | deployment |
      result << {
        "id" => deployment["id"],
        "cell" => [
        deployment["id"],
        deployment["name"],
        deployment["host"],
        deployment["username"],
        deployment["logs_dir"],
        deployment["file"],
        deployment["locality"],
        deployment["environment"],
        deployment["tags"].join(",")]}
    end
    result
  end

end
