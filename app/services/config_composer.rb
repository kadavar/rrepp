class ConfigComposer
  def list_of_config_names
    Project::Config.pluck(:name)
  end

  def update_or_create(config_params, name)
    config = Project::Config.where(name: name).first_or_initialize
    config.update_attributes(config_params.except('jira_custom_fields', 'jira_issue_types'))

    config_params['jira_custom_fields'].each do |key, value|
      custom_field = config.jira_custom_fields.find_or_create_by(name: key)
      custom_field.update_attributes(value: value)
    end

    config.jira_custom_fields.where.not(name: data['jira_custom_fields'].values).destroy_all

    config_params['jira_issue_types'].each do |name, id|
      issue_type = config.jira_issue_types.find_or_create_by(name: name)
      issue_type.update_attributes(jira_id: id)
    end
  end

  def config(name)
    config = Project::Config.find_by(name: name)
    config_hash = config.attributes.except('updated_at', 'created_at', 'name', 'id', 'project_id')

    jira_custom_fields =
      config.jira_custom_fields.map do |custom_field|
        custom_field.attributes.except('created_at', 'updated_at', 'id', 'config_id').values
      end.flatten.map { |name| { name.split.join.underscore => name } }.reduce({}, :merge)

    jira_issue_types =
      config.jira_issue_types.map do |issue_type|
        issue_type.attributes.except('created_at', 'updated_at', 'id', 'config_id').values
      end.map { |a| Hash[*a] }.reduce({}, :merge)

    config_hash.merge!('jira_custom_fields' => jira_custom_fields)
    config_hash.merge!('jira_issue_types'   => jira_issue_types)
  end

  def compose_project_config(project)
    project_config = project.config.attributes

    project_config.merge!('project_name'  => project.name,
                          'log_file_name' => log_file_name(project))

    project_config['jira_custom_fields'] = compose_jira_custom_fields(project.config)

    project_config['jira_issue_types']   = compose_jira_issue_types(project.config)

    project_config
  end

  private

  def compose_jira_custom_fields(config)
    custom_fields = {}

    config.jira_custom_fields.each do |custom_field|
      custom_fields[custom_field.name] = custom_field.value
    end

    custom_fields
  end

  def compose_jira_issue_types(config)
    issue_types = {}

    config.jira_issue_types.each do |issue_type|
      issue_types[issue_type.name] = issue_type.jira_id
    end

    issue_types
  end

  def log_file_name(project)
    file_name = "#{project.name.underscore.gsub(' ', '_')}.log"
    file = open("log/#{file_name}", File::WRONLY | File::APPEND | File::CREAT)

    file_name
  end
end
