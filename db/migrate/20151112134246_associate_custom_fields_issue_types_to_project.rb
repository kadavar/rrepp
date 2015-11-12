class AssociateCustomFieldsIssueTypesToProject < ActiveRecord::Migration
  def change
    remove_column :jira_custom_fields, :config_id
    add_reference :jira_custom_fields, :project

    remove_column :jira_issue_types, :config_id
    add_reference :jira_issue_types, :project
  end
end
