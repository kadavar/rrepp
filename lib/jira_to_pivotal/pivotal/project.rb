module JiraToPivotal
  module Pivotal
    class Project < Pivotal::Base
      attr_accessor :config
      attr_reader :project, :client

      def initialize(config)
        @config = config

        build_project
        @config.delete('tracker_token')
      end

      def build_project
        retryable(can_fail: true, with_delay: true, skip_airbrake: true) do
          @client = TrackerApi::Client.new(token: config['tracker_token'])
          @project  = client.project(config['tracker_project_id'])
        end
      end

      def update_config(options)
        @config.merge!(options)
      end

      # TODO: Rewrite using new gem classes
      def create_story(_story_args)
      end

      def unsynchronized_stories
        load_unsynchronized_stories
      end

      # TODO: Rewrite using new gem classes
      def create_tasks!(_issues, _options)
        # Copy attachments
        # Copy notes
        # Create connection between Jira and Pivotal
      end

      # TODO: Rewrite using new gem classes
      def update_tasks!(_issues)
      end

      def select_task(stories, issue)
        stories.find { |story| story.external_id == issue.key }
      end

      def map_users_by_email
        retryable(can_fail: true, with_delay: true) do
          project.memberships.map(&:person).map { |member| { member.name => member.email } }.reduce({}, :merge)
        end
      end

      private

      def load_unsynchronized_stories
        { to_create: load_to_create_stories, to_update: load_to_update_stories }
      end

      def load_to_create_stories
        stories = usefull_stories.select { |story| story.integration_id.nil? || story_ends_with_nil?(story) }
        stories.map { |story| JiraToPivotal::Pivotal::Story.new(project, story, @config) }
      end

      def load_to_update_stories
        stories = usefull_stories.select { |story| !story.integration_id.nil? && !story_ends_with_nil?(story) }
        stories.map { |story| JiraToPivotal::Pivotal::Story.new(project, story, @config) }
      end

      def story_ends_with_nil?(story)
        story.external_id.present? ? story.external_id.split('-').last == '0' : true
      end

      def usefull_stories
        project.stories(filter: 'story_type:bug,chore,feature state:unstarted,started,finished,delivered,rejected')
      rescue TrackerApi::Error => e
        airbrake_report_and_log(
          e,
          parameters: config.airbrake_message_parameters,
          skip_airbrake: true)
        return {}
      end

      def find_stories_by(attrs = {})
        @project.stories(attrs)
      end
    end
  end
end
