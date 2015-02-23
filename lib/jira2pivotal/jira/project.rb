module Jira2Pivotal
  module Jira
    class Project < Base

      attr_accessor :config

      def initialize(config)
        @config = config
        @start_index = 0

        build_api_client

        @config.merge!(custom_fields: issue_custom_fields)
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

      def options_for_issue(issue=nil)
        { client: build_api_client, project: project, issue: issue }
      end

      def build_issue(attributes, issue=nil)
        attributes = { 'fields' =>  { 'project' =>  { 'id' => project.id } }.merge(attributes) }

        issue = issue.present? ? issue : @client.Issue.build(attributes)
        return Issue.new(options_for_issue(issue)), attributes
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

            unsynchronized_issues << Issue.new(options_for_issue(issue)) #unless already_scheduled?(issue)
          end

          issues = issues.count > per_page ? next_issues : []
        end

        # unsynchronized_issues
        split_issues_for_create_update(unsynchronized_issues)
      end

      def split_issues_for_create_update(issues)
        result = { to_create: [], to_update: [] }

        issues.each do |issue|
          if issue.issue.attrs['fields'][jira_pivotal_field].present?
            result[:to_update] << issue
          else
            result[:to_create] << issue
          end
        end
        result
      end

      def find_issues(jql)
        response = JIRA::Resource::Issue.jql(@client, jql)
      end

      def create_tasks!(stories)
        counter = 0
        puts "\nCreate new issues"

        stories.each do |story|
          putc '.'
          issue, attributes = build_issue story.to_jira(@config[:custom_fields])

          issue.save!(attributes, @config)
          issue.update_status!(story)
          issue.create_notes!(story)
          # issue.add_marker_comment(story.url)

          #*********************************************************************************************************#
          #   We can't grab attachments because there is a bug in gem and it returns all attachments from project   #
          #*********************************************************************************************************#

          story.assign_to_jira_issue(issue.issue.key, url)

          counter += 1
        end

        return counter
      end

      def update_tasks!(stories)
        counter = 0
        puts "\nUpdate exists issues"

        incorrect_jira_ids, correct_jira_ids = check_deleted_issues_in_jira(stories.map(&:jira_issue_id))

        cleaned_stories_count = remove_jira_id_from_pivotal(incorrect_jira_ids, stories)
        jira_issues = find_issues("id in #{map_jira_ids_for_search(correct_jira_ids)}")

        stories.each { |story| update_issue!(story, jira_issues); counter += 1 }

        return counter
      end

      def create_sub_task_for_invosed_issues!(stories)
        story_urls = stories.map{ |story| story.story.url }
        jira_issues = find_issues("project=#{@config['jira_project']} AND 'Pivotal Tracker URL' IN #{map_jira_ids_for_search(story_urls)}")


        counter = 0
        puts "\nUpdate Invoiced issues - create subtasks"

        jira_issues.each do |issue|
          story = stories.find { |story| story.url == issue.send(jira_pivotal_field) }

          next unless story.present?
          putc '.'

          subtask = create_sub_task!(issue)
          story.assign_to_jira_issue(subtask.key, url)

          stories.delete(story)
          counter += 1
        end

        counter
      end

      def update_issue!(story, jira_issues)
        putc '.'

        jira_issue = select_task(jira_issues, story)
        return if jira_issue.nil?

        issue, attributes = build_issue(story.to_jira(@config[:custom_fields]), jira_issue)

        issue.save!(attributes, @config)
        issue.update_status!(story)
      end

      def jira_pivotal_field
        @config[:custom_fields].key(@config['jira_custom_fields']['pivotal_url'])
      end

      def create_sub_task!(issue)
        attributes =
          { 'parent' => { 'id' => parent_id_for(issue) },
            'summary' => issue.fields['summary'],
            'issuetype' => {'id' => '5'},
            'description' => issue.fields['description'],
            jira_pivotal_field => issue.send(jira_pivotal_field)
          }

        issue, attrs = build_issue(attributes)
        issue.save!(attrs, @config)
        issue
      end

      def parent_id_for(issue)
        j2p_issue, attrs = build_issue({}, issue)
        j2p_issue.is_subtask? ? issue.fields['parent']['id'] : issue.id
      end

      def select_task(issues, story)
        issues.find { |issue| issue.key == story.jira_issue_id }
      end

      def issue_custom_fields
        @issue ||= project.issue_with_name_expand
        @issue.names
      end

      private

      def map_jira_ids_for_search(jira_ids)
        jira_ids.present? ? "(#{jira_ids.map { |s| "'#{s}'" }.join(',')})" : "('')"
      end

      def check_deleted_issues_in_jira(pivotal_jira_ids)
        jira_project   = @config['jira_project']
        jira_issues = find_issues("project = #{jira_project} AND 'Pivotal Tracker URL' is not EMPTY" )

        invoiced_issues_ids = jira_issues.select { |issue| issue.status.name == 'Invoiced' }.map(&:key)

        correct_jira_ids   = jira_issues.map(&:key) & pivotal_jira_ids - invoiced_issues_ids
        incorrect_jira_ids = pivotal_jira_ids - correct_jira_ids

        return incorrect_jira_ids, correct_jira_ids
      end

      def remove_jira_id_from_pivotal(jira_ids, stories)
        for_clean_stories = stories.select { |s| jira_ids.include?(s.jira_issue_id) }
        for_clean_stories.each { |story| story.assign_to_jira_issue('nil', 'nil') }

        return for_clean_stories.count
      end

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

  def issue_with_name_expand
    response = client.get(client.options[:rest_base_path] + "/search?jql=project%3D'#{key}'+AND+issuetype+%3D+%22New+Feature%22&maxResults=1&expand=names")
    json = self.class.parse_json(response.body)
    client.Issue.build(json)
  end
end
