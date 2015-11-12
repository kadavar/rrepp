class AddReferencesToProject < ActiveRecord::Migration
  def change
    change_table :projects do |t|
      t.references :pivotal_account
      t.references :jira_account
    end
    add_column :projects, :jira_project, :string
    add_column :projects, :tracker_project_id, :integer
  end
end
