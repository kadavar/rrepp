class JiraAccount < ActiveRecord::Base

  has_many :projects
  validates :name,  uniqueness: true, presence: true
  validates :password , presence: true
  validates :jira_filter , presence: true
end
