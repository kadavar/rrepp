class ProjectConfigsHandler
  require 'find'

  class << self
    def synchronize
      pull_from_config_folder
      push_to_config_folder
    end

    def update_config_file(attributes)
      load_and_update_config(attributes)
    end

    private

    def pull_from_config_folder
      list_of_config_names.each { |name| load_or_create_config(name) }
    end

    def push_to_config_folder
      list_of_config_names.each { |name| create_config_file(name) }
    end

    def load_or_create_config(name)
      data = YAML.load(ERB.new(File.read(config_path(name))).result)
      config_params = data.except('jira_custom_fields', 'jira_issue_types')

      config = Project::Config.where(name: name).first_or_initialize
      config.update_attributes(config_params)

      data['jira_custom_fields'].values.each do |custom_field_name|
        config.jira_custom_fields.find_or_create_by(name: custom_field_name)
      end
      config.jira_custom_fields.where.not(name: data['jira_custom_fields'].values).destroy_all

      data['jira_issue_types'].each do |name, id|
        issue_type = config.jira_issue_types.find_or_create_by(name: name)
        issue_type.update_attributes(jira_id: id)
      end

    rescue Exception => e
      # TODO: Add errors handler to show them on frontend
      Airbrake.notify_or_ignore(e, cgi_data: ENV.to_hash)
      false
    end

    def create_config_file(name)
      return true if File.readable?(config_path(name))

      config = Project::Config.find_by(name: name)
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

      File.open(config_path(name), 'w') { |f| f.write config_hash.to_yaml }

    rescue Exception => e
      # TODO: Add errors handler to show them on frontend
      Airbrake.notify_or_ignore(e, cgi_data: ENV.to_hash)
      false
    end

    def load_and_update_config(attributes)
      data = YAML.load(ERB.new(File.read(config_path(attributes[:old_name]))).result)

      # update config file attributes
      attributes.except(:old_name, :new_name).each { |key, value| data[key] = value }
      File.open(config_path(attributes[:old_name]), 'w') { |f| f.write data.to_yaml }

      # rename config file
      File.rename(config_path(attributes[:old_name]), config_path(attributes[:new_name])) if attributes[:new_name].present?
    end

    def list_of_config_names
      Find.find(Rails.root.join(default_config_path)).select { |p| /.*\.yml$/ =~ p }.map { |path| path.split('/').last.gsub('.yml', '') }
    end

    def default_config_path
      'config/integrations'
    end

    def config_path(name)
      Rails.root.join "#{default_config_path}/#{name}.yml"
    end
  end
end
