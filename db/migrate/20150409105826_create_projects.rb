class CreateProjects < ActiveRecord::Migration
  def change
    create_table :projects do |t|
      t.string   :name
      t.integer  :pid
      t.boolean  :online, default: false
      t.datetime :last_update

      t.timestamps null: false
    end
  end
end
