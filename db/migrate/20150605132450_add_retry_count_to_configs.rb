class AddRetryCountToConfigs < ActiveRecord::Migration
  def change
    add_column :configs, :retry_count, :integer
  end
end
