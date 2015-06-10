class ProjectConfigsHandler
  require 'find'

  class << self
    def synchronize
      pull_from_config_folder
      push_to_config_folder
    end

    private

    def pull_from_config_folder
      list_of_config_names.each { |name| load_or_create_config(name) }
    end

    def push_to_config_folder
      list_of_config_names.each { |name| create_config_file(name) }
    end

    def load_or_create_config(name)
      file_path = Rails.root.join "project_configs/#{name}.yml"

      data = YAML.load(ERB.new(File.read(file_path)).result)
      config_params = data.except('jira_custom_fields', 'jira_issue_types')

      config = Config.where(name: name).first

      if config.present?
        config.update_attributes(config_params)
      else
        config = Config.create(config_params.merge(name: name))
      end

      data['jira_custom_fields'].values.each do |custom_field_name|
        config.jira_custom_fields.find_or_create_by(name: custom_field_name)
      end

      data['jira_issue_types'].each do |name, id|
        config.jira_issue_types.find_or_create_by(name: name, jira_id: id)
      end

    rescue
      # TODO: Add errors handler to show them on frontend
      false
    end

    def create_config_file(name)
      file_path = Rails.root.join "project_configs/#{name}.yml"
      return true if File.readable?(file_path)

      config = Config.find_by(name: name)
      config_hash = config.attributes.except('updated_at', 'created_at', 'name', 'id', 'project_id')

      jira_custom_fields =
        config.jira_custom_fields.map do |custom_field|
          custom_field.attributes.except('created_at', 'updated_at', 'id', 'config_id').values
        end.flatten.map { |name| { name.split.join.underscore => name } }.reduce(Hash.new, :merge)

      jira_issue_types =
        config.jira_issue_types.map do |issue_type|
          issue_type.attributes.except('created_at', 'updated_at', 'id', 'config_id').values
        end.map { |a| Hash[*a] }.reduce(Hash.new, :merge)

      config_hash.merge!('jira_custom_fields' => jira_custom_fields)
      config_hash.merge!('jira_issue_types' => jira_issue_types)

      File.open(file_path, 'w') { |f| f.write config_hash.to_yaml }

    rescue
      # TODO: Add errors handler to show them on frontend
      false
    end

    def list_of_config_names
      Find.find(Rails.root.join('project_configs')).select { |p| /.*\.yml$/ =~ p }.map { |path| path.split('/').last.gsub('.yml', '') }
    end
  end
end
