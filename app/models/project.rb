class Project < ActiveRecord::Base
  has_one :project_config
end
