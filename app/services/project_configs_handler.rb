class ProjectConfigsHandler
  require 'find'

  class << self
    def synchronize
      pull_from_config_folder
      # push_to_config_folder
    end

    private

    def pull_from_config_folder
      list_of_config_names.each { |name| load_config_file(name) }
    end

    def push_to_config_folder
      list_of_config_names.each { |name| create_config_file(name) }
    end

    def load_config_file(name)
      file_name = Rails.root.join "project_configs/#{name}.yml"

      data = YAML.load(ERB.new(File.read(file_name)).result)
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
      #TODO: Add errors handler to show them on frontend
      false
    end

    def list_of_config_names
      Find.find(Rails.root.join('project_configs')).select { |p| /.*\.yml$/ =~ p }.map { |path| path.split('/').last.gsub('.yml', '') }
    end
  end
end
