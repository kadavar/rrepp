class Jira::IssueType < ActiveRecord::Base
  belongs_to :config
end
