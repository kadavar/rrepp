module Jira2Pivotal
  module Logger
    class JiraLogger < Base
      def initialize(logger, config)
        @logger = logger
        @config = config
      end

      def create_issue_log(story. issue)
        log_values(story, issue, 'CREATE')

        @logger.info "#{@jira_issue_for_log} For: #{story.story.id} - #{@connection_for_log}"
      end

      def update_issue_log(story_object, issue_object)
        log_values(story_object, issue_object, 'UPDATE')
        Differ.separator = "\n"

        story, issue = shorcut_for(story_object, issue_object)

        title_diff_for_log(story['title'], issue['title'])     if story['title'].diff?(issue['title'])
        description_diff_for_log(story['desc'], issue['desc']) if story['desc'].diff?(issue['desc'])
        status_diff_for_log(story['status'], issue['status'])  if story['status'].diff?(issue['status'])
      end

      def invoced_issue_log
        log_values(story_object, issue_object, 'INVOICED')

        @logger.info "#{@jira_issue_for_log} Sub Task: #{subtask.key} - #{@connection_for_log}"
      end

      private

      def log_values(story, issue, action)
        @config.merge!('sync_action' => action)
        @connection_for_log = jira_pivotal_connection_for_log(story, issue)
        @jira_issue_for_log = ":: #{issue.key} :: >>"
      end

      def title_diff_for_log(pivotal_title, jira_tittle)
        logger.info "#{@jira_issue_for_log} Title: #{pivotal_title - jira_tittle} - #{@connection_for_log}"
      end

      def description_diff_for_log(pivotal_desc, jira_desc)
        logger.info "#{@jira_issue_for_log} Description: #{pivotal_desc - jira_desc} - #{@connection_for_log}"
      end

      def status_diff_for_log(pivotal_status, jira_status)
        logger.info "#{@jira_issue_for_log} Status: #{pivotal_status - jira_status} - #{@connection_for_log}"
      end

      def shorcut_for(story, issue)
        jira_story = story.to_jira(@config[:custom_fields])

        story_short = {
          'title'  => jira_story['summary'],
          'desc'   => (jira_story['description'].to_s || ''),
          'status' => (story.current_story_status_to_issue_status || ''),
          'points' => (jira_story[jira_pivotal_points].to_s || '')
        }

        jira_short = {
          'title'  => issue.fields['summary'],
          'desc'   => (issue.fields['description'].to_s || ''),
          'status' => (issue.fields['status']['name'].to_s || ''),
          'points' => (issue.fields[jira_pivotal_points].to_i.to_s || '')
        }
        return story_short, jira_short
      end
    end
  end
end
