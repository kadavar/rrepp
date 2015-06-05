class Jira::CustomField < Jira
  belongs_to :config

  validates :name,  uniqueness: true
end
