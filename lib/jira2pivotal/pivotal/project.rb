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
          puts "Can't create Pivotal Story: #{story.errors.uniq}"
          nil
        end
      end
    end
  end

end
