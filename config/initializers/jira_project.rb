JIRA::Resource::Project.class_eval do
  # Returns all the issues for this project
  def issues(start_index=0)
    response = client.get(client.options[:rest_base_path] + "/search?jql=project%3D'#{key}'&startIndex=#{start_index}")
    json = self.class.parse_json(response.body)
    json['issues'].map do |issue|
      client.Issue.build(issue)
    end
  end

  def issues_by_filter(filter_id, start_index=0)
    response = client.get(client.options[:rest_base_path] + "/filter/#{filter_id}?startIndex=#{start_index}")
    filter_data = self.class.parse_json(response.body)

    response = client.get(filter_data['searchUrl'])
    json = self.class.parse_json(response.body)

    json['issues'].map do |issue|
      client.Issue.build(issue)
    end
  end

  def issue_with_name_expand
    response = client.get(client.options[:rest_base_path] + "/search?jql=project%3D'#{key}'+AND+issuetype+%3D+%22New+Feature%22&maxResults=1&expand=names")
    json = self.class.parse_json(response.body)
    client.Issue.build(json)
  end

  def asignable_users
    response = client.get(client.options[:rest_base_path] + "/user/assignable/search?project=#{self.key}")
    json = self.class.parse_json(response.body)
  end
end
