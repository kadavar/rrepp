class AddNameToConfigs < ActiveRecord::Migration
  def change
    add_column :configs, :name, :string
  end
end
