module JiraToPivotal
  module Jira
    class Project < Jira::Base
      attr_accessor :config
      attr_reader :client

      PER_PAGE = 50

      def initialize(init_config)
        @config = init_config
        @start_index = 0

        build_api_client

        config.delete('jira_password')
        config.merge!(custom_fields: issue_custom_fields)
      end

      def issue_custom_fields
        @issue ||= project.issue_with_name_expand

        unless @issue.names.present?
          logger.attrs_log(@issue.inspect, 'Issue with custom fields')
          fail "Can't grep custom fields. Check users permissions of at least one feature"
        end

        @issue.names
      end

      def build_api_client
        @client ||= JIRA::Client.new(
          username:     config['jira_login'],
          password:     config['jira_password'],
          site:         url,
          context_path: '',
          auth_type:    :basic,
          use_ssl:      ssl?
        )
      end

      def project
        retries ||= config['script_repeat_time'].to_i
        @project ||= client.Project.find(config['jira_project'])
      rescue JIRA::HTTPError => error
        retry unless (retries -= 1).zero?

        logger.error_log(error)
        Airbrake.notify_or_ignore(
          error,
          parameters: { config: config.airbrake_message_parameters },
          cgi_data: ENV.to_hash
        )
        fail error
      rescue Errno::EHOSTUNREACH => error
        logger.error_log(error)
        false
      end

      def project_name
        config['jira_project']
      end

      def update_config(options)
        config.merge!(options)
      end

      def ssl?
        config['jira_uri_scheme'] == 'https'
      end

      def url
        config.jira_url
      end

      def options_for_issue(issue = nil)
        { client: client, project: project, issue: issue, config: config }
      end

      def build_issue(attributes, issue = nil)
        attributes = { 'fields' =>  { 'project' =>  { 'id' => project.id } }.merge(attributes) }

        issue = issue.present? ? issue : client.Issue.build(attributes)

        [Issue.new(options_for_issue(issue)), attributes]
      end

      def difference_checker
        @difference_checker ||= DifferenceChecker.new(project, config)
      end

      def next_issues
        list = issues(@start_index)

        if list.present?
          @start_index += PER_PAGE

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
          issues.each do |issue|
            issue.fetch

            # unless already_scheduled?(issue)
            unsynchronized_issues << Issue.new(options_for_issue(issue))
          end

          issues = issues.count > PER_PAGE ? next_issues : []
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

      def find_issues(jql, options = {})
        JIRA::Resource::Issue.jql(client, jql, options)
      rescue JIRA::HTTPError => e
        unless JSON.parse(e.response.body)['errorMessages'].first.include?("does not exist for field 'key'")
          logger.error_log(e)
          Airbrake.notify_or_ignore(
            e,
            parameters: { jql: jql },
            cgi_data: ENV.to_hash
          )
        end

        return []
      end

      def create_tasks!(stories)
        stories.each do |story|
          putc '.'
          next unless story.to_jira(issue_custom_fields)

          issue, attributes = build_issue story.to_jira(issue_custom_fields)

          next unless issue.save!(attributes, config)

          logger.jira_logger.create_issue_log(story, issue, attributes)

          issue.update_status!(story)
          issue.create_notes!(story)
          # issue.add_marker_comment(story.url)

          # ********************************************************************************************************* #
          #   We can't grab attachments because there is a bug in gem and it returns all attachments from project     #
          # ********************************************************************************************************* #

          story.assign_to_jira_issue(issue.issue.key, url)
        end
      end

      def update_tasks!(stories)
        incorrect_jira_ids, correct_jira_ids = check_deleted_issues_in_jira(stories.map(&:jira_issue_id))

        remove_jira_id_from_pivotal(incorrect_jira_ids, stories)

        if correct_jira_ids.present?
          jira_issues = find_issues("id in #{map_jira_ids_for_search(correct_jira_ids)}")
          stories.each { |story| update_issue!(story, jira_issues) }
        end
      end

      def create_sub_task_for_invosed_issues!(stories)
        story_urls = stories.map { |story| story.story.url }

        return unless story_urls.present?

        pivotal_urls = map_jira_ids_for_search(story_urls)
        jql = "project=#{project_name} AND 'Pivotal Tracker URL' IN #{pivotal_urls} AND status = Invoiced"
        jira_issues = find_issues(jql)

        jira_issues.each { |issue| prepare_and_create_sub_task!(issue, stories) }
      end

      def prepare_and_create_sub_task!(issue, stories)
        story = stories.find { |local_story| local_story.url == issue.send(jira_pivotal_field) }

        return false unless story.present?
        putc '.'

        subtask = create_sub_task!(issue, story.url)

        return false unless subtask

        story.assign_to_jira_issue(subtask.key, url)

        old_issue, _attrs = build_issue({}, issue)
        logger.jira_logger.invoced_issue_log(story: story, issue: subtask, old_issue: old_issue)

        stories.delete(story)
        true
      end

      def update_issue!(story, jira_issues)
        putc '.'

        jira_issue = select_task(jira_issues, story)

        return if jira_issue.nil?
        return unless story.to_jira(issue_custom_fields)

        issue, attributes = build_issue(story.to_jira(issue_custom_fields), jira_issue)

        if difference_checker.main_attrs_difference?(attributes, issue)
          logger.jira_logger.update_issue_log(story, issue, attributes)
          return false unless issue.save!(attributes, config)
        end

        # TODO: Disable untill new logic would be finished
        # if difference_checker.status_difference?(jira_issue, story)
        #   return false unless issue.update_status!(story)
        #   logger.jira_logger.update_issue_status_log(story, issue)
        # end

        true
      end

      def create_sub_task!(issue, story_url)
        attributes =
          { 'parent' => { 'id' => parent_id_for(issue) },
            'summary' => issue.fields['summary'],
            'issuetype' => { 'id' => '5' },
            'description' => issue.fields['description'].to_s,
            jira_pivotal_field => issue.send(jira_pivotal_field)
          }

        sub_task, attrs = build_issue(attributes)

        return false unless sub_task.save!(attrs, config)

        logger.jira_logger.create_sub_task_log(story_url: story_url,
                                               issue_key: sub_task.key,
                                               old_issue_key: issue.key,
                                               attrs: attributes)

        sub_task
      end

      def parent_id_for(issue)
        j2p_issue, _attrs = build_issue({}, issue)
        j2p_issue.subtask? ? issue.fields['parent']['id'] : issue.id
      end

      def select_task(issues, story)
        issues.find { |issue| issue.key == story.jira_issue_id }
      end

      def jira_assignable_users
        result = {}
        %w(emailAddress displayName).each do |elem|
          result.merge!(elem.underscore => project.asignable_users.map { |u| { u[elem] => u['name'] } }.reduce({}, :merge))
        end
        result
      end

      private

      def map_jira_ids_for_search(jira_ids)
        "(#{jira_ids.map { |s| "'#{s}'" }.join(',')})"
      end

      def check_deleted_issues_in_jira(pivotal_jira_ids)
        if pivotal_jira_ids.present?
          jira_issues = find_exists_jira_issues(pivotal_jira_ids)

          invoiced_issues_ids = jira_issues.select { |issue| issue.status.name == 'Invoiced' }.map(&:key)

          correct_jira_ids = jira_issues.map(&:key) & pivotal_jira_ids - invoiced_issues_ids
          incorrect_jira_ids = pivotal_jira_ids - correct_jira_ids
        else
          incorrect_jira_ids, correct_jira_ids = Array.new(2) { [] }
        end

        [incorrect_jira_ids, correct_jira_ids]
      end

      def find_exists_jira_issues(pivotal_jira_ids)
        jira_issues = find_issues("key in #{map_jira_ids_for_search(pivotal_jira_ids)}", max_results: 100)

        return jira_issues if jira_issues.present?

        jira_issues = []

        pivotal_jira_ids.each do |key|
          issue = find_issues("key = #{key}")
          jira_issues += issue if issue.present?
        end

        jira_issues
      end

      def remove_jira_id_from_pivotal(jira_ids, stories)
        for_clean_stories = stories.select { |s| jira_ids.include?(s.jira_issue_id) }
        for_clean_stories.each { |story| story.assign_to_jira_issue(nil, url) }
        true
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

      def issues(start_index)
        if config['jira_filter']
          project.issues_by_filter(config['jira_filter'], start_index)
        else
          project.issues(start_index)
        end
      end

      def jira_pivotal_field
        pivotal_url = config['jira_custom_fields']['pivotal_url']
        issue_custom_fields.key(pivotal_url)
      end
    end
  end
end
