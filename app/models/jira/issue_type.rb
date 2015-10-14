class Jira::IssueType < ActiveRecord::Base
  belongs_to :config, class: Project::Config
end
