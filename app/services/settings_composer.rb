class SettingsComposer
    
  def initialize(project)
    @project = project
    @settings=SettingsLoader.new.load!
  end

  def read_settings
    settings = {}
      
    @settings.each { |e,d| settings.merge!({ e => d }) }
    project_attrs = @project.attributes.except('created_at', 'updated_at', 'id')
      
    settings.merge!(project_attrs)
    settings.merge!(@project.pivotal_account.attributes.except('created_at', 'updated_at', 'id'))
      settings.merge!(@project.jira_account.attributes.except('created_at', 'updated_at', 'id','name')) 
      settings.merge!('jira_login' => @project.jira_account.name)
    jira_custom_fields =
          @project.jira_custom_fields.map do |custom_field|
          custom_field.attributes.except('created_at', 'updated_at', 'id', 'config_id').values
        end.flatten.map { |name| { name.split.join.underscore => name } }.reduce({}, :merge)

    jira_issue_types =
          @project.jira_issue_types.map do |issue_type|
          issue_type.attributes.except('created_at', 'updated_at', 'id', 'config_id').values
        end.map { |a| Hash[*a] }.reduce({}, :merge)

   settings.merge!('jira_custom_fields' => jira_custom_fields)
    settings.merge!('jira_issue_types' => jira_issue_types)
    settings.merge!('project_name' => @project.name,
        'project_id' => @project.id,
                        
                          'log_file_name' => log_file_name(@project))
      settings
  end
 def log_file_name(project)
    file_name = "#{project.name.underscore.gsub(' ', '_')}.log"
    file = open("log/#{file_name}", File::WRONLY | File::APPEND | File::CREAT)

    file_name
  end
end
