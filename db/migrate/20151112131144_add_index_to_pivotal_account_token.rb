class AddIndexToPivotalAccountToken < ActiveRecord::Migration
  def change
    add_index :pivotal_accounts, :tracker_token, unique: true
  end
end
