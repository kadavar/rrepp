class Project < ActiveRecord::Base
  has_one :config
  has_one :log
end
