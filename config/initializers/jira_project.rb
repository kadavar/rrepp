JIRA::Resource::Project.class_eval do
  # Returns all the issues for this project
  def issues(start_index=0)
    json = get_to("/search?jql=project%3D'#{key}'&startIndex=#{start_index}")
    json['issues'].map do |issue|
      client.Issue.build(issue)
    end
  end

  def issues_by_filter(filter_id, start_index=0)
    filter_data = get_to("/filter/#{filter_id}?startIndex=#{start_index}")
    json = get_to(filter_data['searchUrl'], true)

    json['issues'].map do |issue|
      client.Issue.build(issue)
    end
  end

  def issue_with_name_expand
    client.Issue.build(get_to("/search?jql=project%3D'#{key}'+AND+issuetype+%3D+%22New+Feature%22&maxResults=1&expand=names"))
  end

  def asignable_users
    get_to("/user/assignable/search?project=#{self.key}")
  end

  def user_permissions
    get_to("/mypermissions?projectKey=#{self.key}")
  end

  def get_to(path, full_path=false)
    get_path = full_path ? path : client.options[:rest_base_path] + path
    self.class.parse_json(client.get(get_path).body)
  end
end
