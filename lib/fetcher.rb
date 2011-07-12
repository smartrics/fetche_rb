require File.dirname(__FILE__) + '/opt_parser.rb'
require File.dirname(__FILE__) + '/deployment_db.rb'
require File.dirname(__FILE__) + '/fetcher_wui.rb'

OptParser.parse(ARGV)
DeploymentDb.instance.load OptParser.options.deployment_json
FetcherWui.run!

