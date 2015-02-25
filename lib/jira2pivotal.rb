$LOAD_PATH << File.expand_path(File.dirname(__FILE__))

require 'active_support/inflector'
ActiveSupport::Inflector.inflections do |inflector|
  inflector.acronym 'Jira2Pivotal'
end

require 'net/http'
require 'open-uri'
require 'certified'
require 'jira'
require 'pivotal-tracker'
require 'yaml'
require 'rails_dt'
require 'pry'
require 'pry-nav'
require 'colorize'
require 'rufus-scheduler'
require 'highline/import'
require 'sidekiq'
require 'sidekiq_script'
require 'daemons'

require 'jira2pivotal/base'
require 'jira2pivotal/config'
require 'jira2pivotal/bridge'

require 'jira2pivotal/jira/base'
require 'jira2pivotal/jira/project'
require 'jira2pivotal/jira/issue'
require 'jira2pivotal/jira/attachment'

require 'jira2pivotal/pivotal/base'
require 'jira2pivotal/pivotal/project'
require 'jira2pivotal/pivotal/story'


module Jira2Pivotal
end
