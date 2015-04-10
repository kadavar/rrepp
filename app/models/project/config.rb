class Config < ActiveRecord::Base
  has_many :jira_custom_fields, class_name: 'Jira::CustomField'
  has_many :jira_issue_types, class_name: 'Jira::IssueType'

  belongs_to :project
end
