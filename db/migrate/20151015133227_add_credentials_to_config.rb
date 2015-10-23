class AddCredentialsToConfig < ActiveRecord::Migration
  def change
    add_column :configs, :jira_password, :string
    add_column :configs, :tracker_token, :string
  end
end
