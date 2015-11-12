class ChangeJiraAccountLoginToName < ActiveRecord::Migration
  def change
    remove_column :jira_accounts, :login
    add_column :jira_accounts, :name, :string
  end
end
