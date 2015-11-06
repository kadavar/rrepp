class AddCurrentJobIdToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :current_job_id, :string
  end
end
