class CreateJiraAccounts < ActiveRecord::Migration
  def change
    create_table :jira_accounts do |t|
      t.string :login
      t.string :password
      t.integer :jira_filter
      t.timestamps null: false
    end
  end
end
