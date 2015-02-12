module Jira2Pivotal
  module Jira
    class Project < Base

      attr_accessor :config

      def initialize(config)
        @config = config
        @start_index = 0

        build_api_client
      end

      def build_api_client
        @client = JIRA::Client.new({
             username:     config['jira_login'],
             password:     config['jira_password'],
             site:         url,
             context_path: '',
             auth_type:    :basic,
             # use_ssl:      false,
             # ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE
         })
      end

      def project
        begin
          @project ||= @client.Project.find(@config['jira_project'])
        rescue JIRA::HTTPError =>  error
          raise StandardError.new 'Sorry, but project not found...'
        end
      end

      def url
        config.jira_url
      end

      def build_issue(attributes, issue=nil)
        attributes = { 'fields' =>  { 'project' =>  { 'id' => project.id } }.merge(attributes) }

        issue = issue.present? ? issue : @client.Issue.build(attributes)
        return Issue.new(@project, issue), attributes
      end

      def next_issues
        list = issues(@start_index)

        if list.present?
          @start_index += per_page

          list
        else
          []
        end
      end

      def unsynchronized_issues
        @unsynchronized_issues ||= load_unsynchronized_issues
      end

      def load_unsynchronized_issues
        unsynchronized_issues = []
        issues = next_issues

        while issues.count > 0

          puts "Issues Find: #{issues.count}"

          issues.each do |issue|
            # Expand the issue with changelog information
            # HACK: This is just a copy of the issue.url function
            def issue.url_old
              prefix = '/'
              unless self.class.belongs_to_relationships.empty?
                prefix = self.class.belongs_to_relationships.inject(prefix) do |prefix_so_far, relationship|
                  prefix_so_far + relationship.to_s + '/' + self.send("#{relationship.to_s}_id") + '/'
                end
              end

              if @attrs['self']
                @attrs['self'].sub(@client.options[:site],'')
              elsif key_value
                self.class.singular_path(client, key_value.to_s, prefix)
              else
                self.class.collection_path(client, prefix)
              end
            end

            # Override the issue url to get changelog information
            def issue.url
              self.url_old + '?expand=changelog'
            end

            issue.fetch

            unsynchronized_issues << Issue.new(self, issue) unless already_scheduled?(issue)
          end

          issues = issues.count > per_page ? next_issues : []
        end

        unsynchronized_issues
      end

      def find_issues(jql)
        JIRA::Resource::Issue.jql(@client, jql)
      end

      private

      def comment_text
        'A Pivotal Tracker story has been created for this Issue'
      end

      def already_scheduled?(jira_issue)
        jira_issue.comments.each do |comment|
          return true if comment.body =~ Regexp.new(comment_text)
        end

        false
      end

      def per_page
        50
      end

      def issues(start_index)
        if config['jira_filter']
          project.issues_by_filter(config['jira_filter'], start_index)
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
end
