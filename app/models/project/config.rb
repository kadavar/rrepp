class Project::Config < ActiveRecord::Base
  self.table_name = 'configs'
  has_many :jira_custom_fields, class_name: 'Jira::CustomField'
  has_many :jira_issue_types, class_name: 'Jira::IssueType'

  belongs_to :project

  validates :name,  uniqueness: true

  accepts_nested_attributes_for :jira_issue_types
  accepts_nested_attributes_for :jira_custom_fields

  after_update :update_config_file
  before_destroy :delete_config_file

  def delete_config_file
    File.delete(Rails.root.join "config/integrations/#{name}.yml")
  end

  def update_config_file
    # TODO: Write logic
  end
end
