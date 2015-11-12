class AddIndexToJiraLogin < ActiveRecord::Migration
  def change
    add_index :jira_accounts, :login, unique: true
  end
end
