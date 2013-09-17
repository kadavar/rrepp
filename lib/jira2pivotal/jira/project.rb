module Jira2Pivotal
  module Jira
    class Project < Base

      def initialize(config)
        @@config = config

        @client = JIRA::Client.new({
          username:     @@config['jira_login'],
          password:     @@config['jira_password'],
          site:         @@config.jira_url,
          context_path: '',
          auth_type:    :basic,
          use_ssl:      false,
          #ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE
        })

        @start_index = 0
      end

      def project

        DT.p @@config
        @project ||= @client.Project.find(@@config['jira_project'])
      end



      def next_issues
        list = issues(@start_index)

        if list.any?
          @start_index += per_page
          list
        else
          false
        end
      end

      private


      def per_page
        50
      end

      def issues(start_index)
        if @@config['jira_filter']
          project.issues_by_filter(@@config['jira_filter'], start_index)
        else
          project.issues(start_index)
        end

      end

    end
  end
end


JIRA::Resource::Project.class_eval do
  # Returns all the issues for this project
  def issues(start_index=0)
    DT.p 'HERE'
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

    DT.p json

    json['issues'].map do |issue|
      client.Issue.build(issue)
    end
  end

end
