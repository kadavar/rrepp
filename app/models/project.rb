class Project < ActiveRecord::Base
  has_one :config, class_name: 'Project::Config', dependent: :destroy
  has_one :log

  scope :projects_to_sync, -> { where(active: true) }

  def log_name
    name.underscore.gsub(' ', '_')
  end

  def worker_status
    Sidekiq::Status::status(current_job_id)
  end
end
