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
        binding.pry
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

        # unsynchronized_issues
        split_issues_for_create_update(unsynchronized_issues)
      end

      def split_issues_for_create_update(issues)
        result = { to_create: [], to_update: [] }
        issues.each do |issue|
          if issue.issue.attrs['fields']['customfield_10200'].present?
            result[:to_create] << issue
          else
            result[:to_update] << issue
          end
        end
        result
      end

      def find_issues(jql)
        JIRA::Resource::Issue.jql(@client, jql)
      end

      def create_tasks!(stories)
        counter = 0
        puts 'Create new issues'

        stories.each do |story|
          putc '.'

          issue, attributes = build_issue story.to_jira

          issue.save!(attributes, @config)
          issue.update_status!(jira.build_api_client, story)
          issue.create_notes!(story)
          issue.add_marker_comment(story.url)

          #*********************************************************************************************************#
          #   We can't grab attachments because there is a bug in gem and it returns all attachments from project   #
          #*********************************************************************************************************#

          story.assign_to_jira_issue(issue.issue.key, jira.url)

          counter += 1
        end

        return counter
      end

      def update_tasks!(stories)
        counter = 0
        puts 'Update exists issues'

        jira_issues = jira.find_issues("id in #{@pivotal.map_stories_by_jira_id(stories)}")

        stories.each do |story|
          putc '.'

          jira_issue = select_task(jira_issues, story)
          issue, attributes = build_issue(story.to_jira, jira_issue)

          issue.save!(attributes, @config)
          issue.update_status!(jira.build_api_client, story)

          counter += 1
        end

        return counter
      end

      def select_task(issues, story)
        issues.find { |issue| issue.attrs['key'] == story.jira_issue_id }
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
