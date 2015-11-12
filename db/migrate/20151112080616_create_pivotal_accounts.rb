class CreatePivotalAccounts < ActiveRecord::Migration
  def change
    create_table :pivotal_accounts do |t|
      t.string :name
      t.string :tracker_token
      t.timestamps null: false
    end
  end
end
