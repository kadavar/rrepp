class Project < ActiveRecord::Base
  has_one :config
  has_one :log

  def log_name
    name.underscore.gsub(' ', '_')
  end
end
