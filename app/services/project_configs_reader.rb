class ProjectConfigsReader
  def load_config(path)
    data = YAML.load(ERB.new(File.read(path)).result)
    data.except('jira_custom_fields', 'jira_issue_types')
  end
end
