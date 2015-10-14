class CreateJiraIssueTypes < ActiveRecord::Migration
  def change
    create_table :jira_issue_types do |t|
      t.string     :name
      t.integer    :jira_id
      t.references :config

      t.timestamps null: false
    end
  end
end
