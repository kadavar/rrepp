class CreateConfigs < ActiveRecord::Migration
  def change
    create_table :configs do |t|
      t.integer :tracker_project_id

      t.string  :jira_login
      t.string  :jira_host
      t.string  :jira_uri_scheme
      t.string  :jira_project
      t.integer :jira_port
      t.integer :jira_filter

      t.integer :script_first_start
      t.string  :script_repeat_time

      t.references :project

      t.timestamps null: false
    end
  end
end
