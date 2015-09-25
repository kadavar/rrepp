module JiraToPivotal
  module Jira
    class SubtasksHandler < Base
      attr_reader :jira_project, :project_name, :config

      def initialize(options = {})
        @config       = options[:config]
        @jira_project = options[:jira_project]
        @project_name = options[:project_name]
      end

      def create_sub_tasks!(stories)
        story_urls = stories.map { |story| story.story.url }

        return unless story_urls.present?

        pivotal_urls = jira_project.map_jira_ids_for_search(story_urls)
        jql = "project=#{project_name} AND 'Pivotal Tracker URL' IN #{pivotal_urls} AND status IN (Invoiced, Reported)"
        jira_issues = jira_project.find_issues(jql)

        jira_issues.each { |issue| prepare_and_create_sub_task!(issue, stories) }
      end

      private

      def prepare_and_create_sub_task!(issue, stories)
        story = stories.find { |local_story| local_story.url == issue.send(jira_pivotal_field) }

        return false unless story.present?

        subtask = create_sub_task!(issue, story.url)

        return false unless subtask

        story.assign_to_jira_issue(subtask.key, url)

        old_issue, _attrs = jira_project.build_issue({}, issue)
        logger.jira_logger.invoced_issue_log(story: story, issue: subtask, old_issue: old_issue)

        stories.delete(story)
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

        sub_task, attrs = jira_project.build_issue(attributes)
        return false unless sub_task.save!(attrs, config)

        logger.jira_logger.create_sub_task_log(story_url: story_url,
                                               issue_key: sub_task.key,
                                               old_issue_key: issue.key,
                                               attrs: attributes)

        sub_task
      end

      def parent_id_for(issue)
        j2p_issue, _attrs = jira_project.build_issue({}, issue)
        j2p_issue.subtask? ? issue.fields['parent']['id'] : issue.id
      end
    end
  end
end
