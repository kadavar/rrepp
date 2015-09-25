class ConfigComposer
  def list_of_config_names
    Project::Config.pluck(:name)
  end

  def update_or_create(config_params, name)
    binding.pry
    config = Project::Config.where(name: name).first_or_initialize

    config_params['jira_custom_fields'].values.each do |custom_field_name|
      config.jira_custom_fields.find_or_create_by(name: custom_field_name)
    end

    config.jira_custom_fields.where.not(name: data['jira_custom_fields'].values).destroy_all

    config_params['jira_issue_types'].each do |name, id|
      issue_type = config.jira_issue_types.find_or_create_by(name: name)
      issue_type.update_attributes(jira_id: id)
    end

    binding.pry
    config.update_attributes(config_params.except('jira_custom_fields', 'jira_issue_types'))
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
    config_hash.merge!('jira_issue_types' => jira_issue_types)
  end
end
