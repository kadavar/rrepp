class Jira::IssueType < ActiveRecord::Base
  belongs_to :project
end
