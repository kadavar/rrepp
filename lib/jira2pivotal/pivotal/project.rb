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

      def load_unsynchronized_stories
        @project.stories.all(story_type: %w(bug chore feature)).keep_if { |story| story.jira_url.nil? }.map { |story| Story.new(@project, story) }
      end
    end
  end

end
