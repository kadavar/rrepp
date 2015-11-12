class JiraAccount < ActiveRecord::Base
  validates :login,  uniqueness: true, presence: true
  validates :password , presence: true
  validates :jira_filter , presence: true
end
