class AddEnabledAndStatusesToProject < ActiveRecord::Migration
  def change
    add_column :projects, :active, :boolean, default: false
    add_column :projects, :last_synchronization_status, :string
    add_column :projects, :last_synchronization_message, :string
  end
end
