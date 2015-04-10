class CreateJiraCustomFields < ActiveRecord::Migration
  def change
    create_table :jira_custom_fields do |t|
      t.string     :name
      t.references :config

      t.timestamps null: false
    end
  end
end
