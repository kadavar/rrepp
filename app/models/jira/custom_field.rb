class Jira::CustomField < Jira
  belongs_to :config, class: Project::Config
end
