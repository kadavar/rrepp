class Project < ActiveRecord::Base
  has_one :config, class_name: 'Project::Config', dependent: :destroy
  has_one :log

  def log_name
    name.underscore.gsub(' ', '_')
  end
end
