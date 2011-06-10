require File.dirname(__FILE__) + '/fetcher_ui.rb'
require File.dirname(__FILE__) + '/opt_parser.rb'
require File.dirname(__FILE__) + '/deployment.rb'

options = OptParser.parse(ARGV)
deployment = Deployment.new(options.deployment_json)
ui = FetcherUi.new(deployment)
ui.loop()
ui.show_selections()

#puts '--- environments'
#p DEPLOYMENTS.environments
#puts '--- environments(:env => :demo)'
#p DEPLOYMENTS.environments(:env => :demo)
#puts '--- localities'
#p DEPLOYMENTS.localities
#puts '--- localities(:env => :demo)'
#p DEPLOYMENTS.localities(:env => :demo)
#puts '--- localities(:env => :demo, :loc => :lon)'
#p DEPLOYMENTS.localities(:env => :demo, :loc => :lon)
#puts '--- component'
#p DEPLOYMENTS.components
#puts '--- component(:env => :demo)'
#p DEPLOYMENTS.components(:env => :demo)
#puts '--- component(:env => :demo, :loc => :tky)'
#p DEPLOYMENTS.components(:env => :demo, :loc => :tky)
#puts '--- component(:env => :demo, :loc => :lon, :comp => :epricer)'
#p DEPLOYMENTS.components(:env => :demo, :loc => :lon, :comp => :epricer)
#puts '--- hosts'
#p DEPLOYMENTS.hosts
#puts '--- hosts(:env => :demo)'
#p DEPLOYMENTS.hosts(:env => :demo)
#puts '--- hosts(:env => :demo, :loc => :lon)'
#p DEPLOYMENTS.hosts(:env => :demo, :loc => :lon)
#puts '--- hosts(:env => :demo, :loc => :lon, :comp => :epricer)'
#p DEPLOYMENTS.hosts(:env => :demo, :loc => :lon, :comp => :epricer)
#puts '--- hosts(:env => :demo, :loc => :lon, :host => "ln7d4321apx")'
#p DEPLOYMENTS.hosts(:env => :demo, :loc => :lon, :host => "ln7d4321apx")

