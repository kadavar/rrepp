module Jira2Pivotal
  module Pivotal
    class Project < Base

      attr_accessor :config

      def initialize(config)
        @config = config

        build_project
      end

      def build_project
        PivotalTracker::Client.token = config['tracker_token']
        @project = PivotalTracker::Project.find(config['tracker_project_id'])
      end

      def create_story(story_args)
        story = @project.stories.create(story_args)
        if story.errors.empty?
          Story.new(@project, story)
        else
          puts "Can't create Pivotal Story: #{story.errors.errors.uniq.join(', ')}"
          nil
        end
      end

      def unsynchronized_stories
        @unsynchronized_stories ||= load_unsynchronized_stories
      end

      def map_stories_by_jira_id(stories)
        "(#{stories.map(&:jira_issue_id).join(', ')})"
      end

      private

      def load_unsynchronized_stories
        { to_create: load_to_create_stories, to_update: load_to_update_stories }
      end

      # TODO Refactor 2 methods below
      def load_to_create_stories
        usefull_stories.select { |story| story.jira_url.nil? }.map { |story| Story.new(@project, story, @config) }
      end

      def load_to_update_stories
        usefull_stories.select { |story| !story.jira_url.nil? }.map { |story| Story.new(@project, story, @config) }
      end

      def usefull_stories
        @project.stories.all(story_type: %w(bug chore feature), state: %w(unstarted started finished delivered rejected))
      end
    end
  end

end
