class Jira < ActiveRecord::Base
  self.abstract_class = true
  self.table_name_prefix = 'jira_'
end
