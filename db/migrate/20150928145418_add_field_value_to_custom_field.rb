class AddFieldValueToCustomField < ActiveRecord::Migration
  def change
    add_column :jira_custom_fields, :value, :string
  end
end
