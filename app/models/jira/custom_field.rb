class Jira::CustomField < Jira
  belongs_to :config, class: Project::Config

  validates :name,  uniqueness: true
end
